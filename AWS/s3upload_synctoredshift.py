#!/usr/bin/env python
import os
import sys
import boto
from boto.s3.key import Key
import psycopg2
import jprops
import collections
import json
import datetime
import logging
from optparse import OptionParser
#import argparse

# Change Log 
# version 1.0 - Utility to upload files / directory to S3 and then sync those files to Redshift by using a manifest for faster processing. 


#Enable Standardized Logging
logging.basicConfig(format='%(asctime)s  %(levelname)s s3_redshift_rync.py %(message)s', level=logging.INFO)

#Function to retrive the manifest file with list of all files to be synced to Redshift from the last sync point
def s3uploadNgetManifest(bucketname,path,source):
  manifest = {'entries': []}
  dt=datetime.datetime.now().strftime("%Y%m%d") 
  logging.info("Start uploading from %s to %s/%s/%s",source,bucketname,path,dt)
# Create a Manifest File 
  conn = boto.connect_s3()
  try:
    bucket = conn.get_bucket(bucketname)
    count = 0
    for fpath,dir,files in os.walk(source):
     for file in files: 
       # Join the two strings in order to form the full filepath.
       filepath = os.path.join(fpath, file)
       key_upload = Key(bucket)
       key_upload.key = os.path.join(path,dt,file)
       logging.info("Uploadig file - %s", filepath)
       key_upload.set_contents_from_filename(filepath)
       manifest['entries'].append({
                    'url': '/'.join(['s3:/', bucketname,path,dt,file]),
                    'mandatory': bool(1)
                    })
       count+=1
    if count == 0:
	return "",""
    logging.info("Found %d files to be synced to Redshift",count)
    keypath = 'amanifest/filestosync_' + datetime.datetime.now().strftime("%Y%m%d_%H%M%S") + '.json'
    logging.info(" Generating manifest file   %s", keypath) 
    key = Key(bucket, keypath)
    key.set_contents_from_string(
            json.dumps(manifest, sort_keys=True, indent=4)
        )
    logging.info("Generated and Loaded Manifest to S3.")
    return keypath
  except Exception, ex:
    logging.error(ex)
    return ""

# Function to delete the manifest after succesful sync with redshift
def deleteManifest(bucketname,keypath):
    logging.info("Deleting manifest file %s",keypath)
    conn = boto.connect_s3()
    try:
      bucket = conn.get_bucket(bucketname)
      key = Key(bucket, keypath)
      bucket.delete_key(key) 
      logging.info("Successfully deleted manifest file %s",keypath)
      return 0
    except Exception, ex:
     logging.error("Unable to delete manifest file %s",keypath)
     logging.error(ex)
     return 1
   
# Function to copy the data from S3 to Redshift
def copy2redshiftfromManifest(manifest):
# Upload the manifest to S3 
  try:
    logging.info("Starting sync from S3 to Redshift")
    rconn = psycopg2.connect(database=db, host=dbhost, port=port, user=username, password=password)
    cur = rconn.cursor()
    cur.execute("copy %s from 's3://%s/%s' credentials IAM_ROLE '%s' gzip DELIMITER ',' IGNOREHEADER 1 manifest;" %(dbtable,bucketname,manifest,iamrole))
    logging.info("Completed file sync to Redshift");
    rconn.commit()
    return 0
  except psycopg2.Error,e:
    logging.error("Unable to sync files to Redshift");
    logging.error(e) 
    return 1

# Function to delete the files after succesful upload to S3 and sync to redshift
def deletefiles(source):
    logging.info("Start delete of source data files")
    for fpath,dir,files in os.walk(source):
     for file in files: 
       # Join the two strings in order to form the full filepath.
       filepath = os.path.join(fpath, file)
       logging.info("Deleting file %s",filepath)
       os.remove(filepath) 
    logging.info("Completed delete of source data")


if __name__ == "__main__":
# For Python 2.7 Use the below 
#    parser = argparse.ArgumentParser(description='Upload to S3 and Sync with Redshift')
#    parser.add_argument('-c', dest='profile',
#                        required=True,
#                   help='Configuration file for the program')
#    parser.add_argument('-sf', dest='source_file',
#                        required=True,
#                   help='Location of Files or directory to upload and sync to redshift')
#    parser.add_argument('-r', dest='deletesource',action="store_true",
#                        required=False,
#                   help='After succesful upload Delete the source files or directory')


    parser = OptionParser()
    parser.add_option('--propfile', dest='propfile', action='store', 
                   help='Configuration file for the program')
    parser.add_option('--source', dest='source',
                   help='Location of Files or directory to upload and sync to redshift')
    parser.add_option('--deletesource', dest='deletesource',action="store_true",
                   help='After succesful upload Delete the source files or directory')
    parser.add_option('--awsbucket', dest='awsbucket', action='store',
		   help='S3 bucket name to store store source data')
    parser.add_option('--awsiamrole', dest='awsiamrole', action='store',
                  help='IAM Role to use for S3 access')
    parser.add_option('--awspath',dest='awspath', action='store',
		   help='S3 path to store source data. Date will be created before the folder in this path')
    parser.add_option('--redshiftdb', dest='db' , action='store',
		   help='Redshift Database for target')
    parser.add_option('--redshiftdbtable', dest='dbtable' , action='store',
		   help='Redshift target table to store the data from S3')

    (options, args) = parser.parse_args();
    if not options.propfile:   # if filename is not given
        parser.error(' --propfile < Property file > - Is required')
    propfile = options.propfile

    if not options.source:
        parser.error(' --source Location of source folder or patter providing list of files to be uploaded to S3 and Sync to redshift. This is required. ')
    source = options.source
    deletesource = False;
    if options.deletesource:
	deletesource = True; 
    if os.path.isfile(propfile) == False:
      raise Exception('Prop File specified does not exist.')
    with open(propfile) as fp:
      properties = jprops.load_properties(fp, collections.OrderedDict);
      dbhost = properties['redshift.dbhost']
      port = properties['redshift.port']
      username = properties['redshift.username']
      password = properties['redshift.password']
      if not options.db:
      	db = properties['redshift.db']
      else:
        db = options.db

      if not options.awsiamrole:
          iamrole=properties['aws.redshift.iam.role']
      else:
          iamrole = options.awsiamrole

      if not options.awsbucket:
      	bucketname = properties['aws.bucket']
      else:
        bucketname = options.bucketname
      if not options.awspath:
        path = properties['aws.path'] 
      else:
	path = options.awspath

      if not options.dbtable:
      	dbtable = properties['redshift.dbtable']    
      else:
        dbtable = options.dbtable

      workdir = properties['sync.work.dir']

# Upload Files to S3 and Create Manifest file
      manifest=s3uploadNgetManifest(bucketname,path,source)
      if manifest != "":
# Start copy of all the keys
      	copyRtnCode = copy2redshiftfromManifest(manifest)	
# Delete manifest file
        if copyRtnCode == 0:
        	deleteManifest(bucketname,manifest)
# Reset the marker to the last key value thats syned to redis
      		if deletesource:
			deletefiles(source)
    sys.exit(0)
