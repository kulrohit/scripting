#!/usr/bin/env python
import os
import sys
import boto
import psycopg2
import jprops
import collections
import json
import datetime
import logging
from boto.s3.key import Key
from boto.s3.connection import OrdinaryCallingFormat
from optparse import OptionParser

#Enable Standardized Logging
logging.basicConfig(format='%(asctime)s  %(levelname)s copy_s3toredshift.py %(message)s', level=logging.INFO)

#Function to move from one path to other
def movefiles(bucketname,path,destbucketname,destpath,s3keystocopy):
  period_char='.'
  logging.info("Moving Files from %s to %s",path,destpath)
  conn = boto.connect_s3()
  try:
    bucket = conn.get_bucket(destbucketname,validate=True)
    for key in s3keystocopy:
      if period_char in key.name:
	newkeyname=key.name.replace(path,destpath)
        newkey=Key(bucket,newkeyname)
	logging.info("Copying key from  %s to %s",key.name,newkeyname)
	bucket.copy_key(newkey,bucketname,key.name)
	logging.info("Delete Key %s",key.name)
	bucket.delete_key(key)
    logging.info("Completed Moving Files from %s to %s",path,destpath)
    return 0
  except Exception, ex:
    logging.error(ex)
    return 1


#Function to retrive the manifest file with list of all files to be synced to Redshift from the last sync point
def getmanifestfile(bucketname,iprefix,imarker):
  manifest = {'entries': []}

# Create a Manifest File 
  logging.info("Starting File copy bucket %s from  %s",bucketname,imarker)
  conn = boto.connect_s3()
  try:
    logging.debug("connecting to bucket")
    bucket = conn.get_bucket(bucketname)
    keys = bucket.list(marker=imarker,prefix=iprefix)
    count = 0
    for key in keys:
       manifest['entries'].append({
                    'url': '/'.join(['s3:/', key.bucket.name, key.name]),
                    'mandatory': bool(1)
                    })
       logging.info("Sync - %s", key.name)
       last=key.name
       count+=1
    if count == 0:
        logging.info("No Files found to be copyied to Redshift")
	return "","",""
    logging.info("Found %d files to be copied to Redshift",count)
    keypath = 'amanifest/filestosync_' + datetime.datetime.now().strftime("%y%m%d_%H%M%S") + '.json'
    logging.info("Generating Manifest file %s", keypath) 
    key = Key(bucket, keypath)
    key.set_contents_from_string(
            json.dumps(manifest, sort_keys=True, indent=4)
        )
    logging.info("Generated and Loaded Manifest to S3.")
    return keypath,last,keys
  except Exception, ex:
    logging.error(ex)
    return ""

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
   

def copy2redshiftfromManifest(manifest,ignoreheader):
# Upload the manifest to S3 
  try:
    logging.info("Starting sync from S3 to Redshift")
    rconn = psycopg2.connect(database=db, host=dbhost, port=port, user=username, password=password)
    cur = rconn.cursor()
    if ignoreheader:
    	cur.execute("copy %s from 's3://%s/%s' IAM_ROLE '%s' gzip DELIMITER '	' IGNOREHEADER 1  manifest;" %(dbtable,bucketname,manifest,iamrole))
    else:
    	cur.execute("copy %s from 's3://%s/%s' IAM_ROLE '%s' gzip DELIMITER '	'  manifest;" %(dbtable,bucketname,manifest,iamrole))
    logging.info("Completed file sync to Redshift");
    rconn.commit()
    return 0
  except psycopg2.Error,e:
    logging.error("Unable to sync files to Redshift");
    logging.error(e) 
    return 1

if __name__ == "__main__":
  args_processed=False
  move=False
  ignoreheader=True
  if (len(sys.argv) == 2):
    propfile = sys.argv[1]
    if ( propfile != "-h" ):
    	if os.path.isfile(propfile) == False:
      		raise Exception('Configuration specified does not exist.')
    	with open(propfile) as fp:
                 args_processed=True
     		 properties = jprops.load_properties(fp, collections.OrderedDict);
     		 dbhost = properties['redshift_host']
      		 port = properties['redshift_port']
      		 username = properties['redshift_user']
      		 password = properties['redshift_password']
      		 db = properties['redshift_db']
             	 iamrole=properties['iam_role']
      		 bucketname = properties['s3_bucketname']
      		 path = properties['s3_path'] 
      		 dbtable = properties['redshift_dbtable']    
		 if properties.has_key('s3_ignoreheader'):
	   		signoreheader = properties['s3_ignoreheader'];
	   		if ( signoreheader.lower() == "true" ):
				ignoreheader=True
			else:
				ignoreheader=False
			
		 if properties.has_key('s3_moveaftercopy'):
	   		smove = properties['s3_moveaftercopy'];
	   		if ( smove.lower() == "true" ):
				move=True
		 if move:
          		if properties.has_key('s3_destpath'):
          			awsdestpath = properties['s3_destpath']
	  		if properties.has_key('s3_destbucket'):
             			awsdestbucket = properties['s3_destbucket']
          		if properties.has_key('s3_errorpath'):
          			awserrorpath = properties['s3_errorpath']
	  		if properties.has_key('s3_destbucket'):
             			awserrorbucket = properties['s3_errorbucket']
		 else:
      		 	if  properties.has_key('temp_dir'):
      		 		workdir = properties['temp_dir']
                 		markerfile = workdir + '/' + bucketname
			else:
				workdir = "/tmp/" + bucketname


  if ( args_processed == False): 
# Use the new options.
    parser = OptionParser()
    parser.add_option('--configfile', dest='propfile', action='store',
                   help='Configuration file for the program')
    parser.add_option('--s3bucket', dest='awsbucket', action='store',
		   help='S3 bucket name to store store source data')
    parser.add_option('--s3path',dest='awspath', action='store',
		   help='S3 path to store source data. Date will be created before the folder in this path')
    parser.add_option('--redshiftdb', dest='db' , action='store',
		   help='Redshift Database for target')
    parser.add_option('--redshiftdbtable', dest='dbtable' , action='store',
		   help='Redshift target table to store the data from S3')
    parser.add_option('--syncfile', dest='syncfile' , action='store',
		   help='Local file to track S3 marker')
    parser.add_option('--moveaftercopy', dest='move' , action='store_false',
		   help='Move S3 files to destination after succesfully sync to Redshift')
    parser.add_option('--s3destbucket',dest='awsdestbucket', action='store',
		   help='Name of Destination S3 bucket to move the after redshift sync')
    parser.add_option('--s3destpath',dest='awsdestpath', action='store',
		   help='Location of S3 path to move the after the redshift sync')
    parser.add_option('--s3errorbucket',dest='awserrorbucket', action='store',
		   help='Name of Destination S3 bucket to move on failure of redshift sync')
    parser.add_option('--s3errorpath',dest='awserrorpath', action='store',
		   help='Location of S3 path to move on failure of redshift sync')
    parser.add_option('--awsiamrole', dest='awsiamrole', action='store',
                  help='IAM Role to use for S3 access')


    (options, args) = parser.parse_args();
    if not options.propfile:   # if filename is not given
        parser.error(' --configfile < Configuration file > - Is required')
    propfile = options.propfile

    if os.path.isfile(propfile) == False:
      raise Exception('Configuraiton File specified does not exist.')
    with open(propfile) as fp:
      properties = jprops.load_properties(fp, collections.OrderedDict);
      dbhost = properties['redshift_host']
      port = properties['redshift_port']
      username = properties['redshift_user']
      password = properties['redshift_password']
      if not options.db:
      	db = properties['redshift_db']
      else:
        db = options.db

      if not options.awsiamrole:
          iamrole=properties['iam_role']
      else:
          iamrole = options.awsiamrole

      if not options.awsbucket:
      	bucketname = properties['s3_bucketname']
      else:
        bucketname = options.awsbucket

      if not options.awspath:
        path = properties['s3_path']
      else:
    	path = options.awspath

      if not options.dbtable:
      	dbtable = properties['redshift_dbtable']
      else:
        dbtable = options.dbtable

      if not options.move:
	if properties.has_key('s3_moveaftercopy'):
	   smove = properties['s3_moveaftercopy'];
	   if ( smove.lower() == "true" ):
		move=True
      else:
	move=options.move

      logging.info("Value of Move - %s",move);
      if move:
	if not options.awsdestpath:
	  logging.info("Retrieving s3_destpath from props file")
          if properties.has_key('s3_destpath'):
          	awsdestpath = properties['s3_destpath']
	else:
	  awsdestpath = options.awsdestpath

	if not options.awsdestbucket:
	  if properties.has_key('s3_destbucket'):
             awsdestbucket = properties['s3_destbucket']
	else:
	  awsdestbucket = options.awsdestbucket

        if not options.awserrorpath:
	 if properties.has_key('s3_errorpath'):
          awserrorpath = properties['s3_errorpath']
        else:
          awserrorpath = options.awserrorpath

        if not options.awserrorbucket:
	 if properties.has_key('s3_errorbucket'):
          awserrorbucket = properties['s3_errorbucket']
        else:
          awserrorbucket = options.awserrorbucket


      if not move:	
       if not options.syncfile:
        workdir = properties['temp_dir']
        markerfile = workdir + '/' + bucketname
       else:
        markerfile = options.syncfile

# Retrieve the prev sync position from the work directory. 
  if not move:
   logging.info("Checking last sync location at %s", markerfile)
   if os.path.isfile(markerfile) == False:
          marker=''
   else:
          file = open(markerfile, 'r')
          marker=file.readline()
          file.close()
  else:
     marker=''

# Get all the keys from Bucket from the marker position
  s3keystocpymanifest,marker,s3keystocpy=getmanifestfile(bucketname,path,marker)

  if s3keystocpy != "":
# Start copy of all the keys
      	copyRtnCode = copy2redshiftfromManifest(s3keystocpymanifest,ignoreheader)	
# Delete manifest file
        deleteManifest(bucketname,s3keystocpymanifest)

# Check if files need to be moved to a different s3path
	if move == True:
	   marker=""
# Succesful Redshift Sync move to Destination Folder else move to Error Folder
	   if copyRtnCode == 0:
		logging.info("Sunccesfully Synced to Redshift starting to move to Destination Folder")
		movefiles(bucketname,path,awsdestbucket,awsdestpath,s3keystocpy)
	   else: 
		logging.info("Error sync to Redshift starting to move to Error Folder")
		movefiles(bucketname,path,awserrorbucket,awserrorpath,s3keystocpy)
	
# Reset the marker to the last key value thats syned to redis
        if marker != "" and copyRtnCode == 0:
         file=open(markerfile, 'w')
         file.write(marker)
         file.close()
         sys.exit(0)
