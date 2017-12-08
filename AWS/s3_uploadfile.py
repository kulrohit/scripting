#!/usr/bin/env python
import os
import sys
import boto
from boto.s3.key import Key
import boto.exception
import collections
import jprops
import logging

#Initialize logging 
logging.basicConfig(format='%(asctime)s  %(levelname)s s3_uploadfile %(message)s', level=logging.INFO)

def main(bucket,s3path,s3key,s3value):
		
        try:
		logging.info("Uploading file %s with key=%s, path=%s, bucket=%s",s3value,s3key,s3path,bucket)
    		conn = boto.connect_s3()
		logging.debug("Connected to S3")
        	bucket = conn.get_bucket(bucket)
		logging.debug("Retrieved handle to bucket")
        	key_upload = Key(bucket)
        	key_upload.key = os.path.join(s3path, s3key)
		logging.debug("Start upload of file")
        	key_upload.set_contents_from_filename(s3value)
		return 0
    	except Exception, ex:
        	logging.error("%s", ex.error_message)
		return 1

if __name__ == "__main__":
   # print sys.argv
    if len(sys.argv) >= 6:
       file = sys.argv[1]
       if os.path.isfile(file) == False:
           raise Exception('Property file  specified does not exist.')
       s3bucket=sys.argv[2]
       s3path=sys.argv[3]
       s3key=sys.argv[4]
       s3value=sys.argv[5]
       if os.path.isfile(s3value) == False:
           raise Exception('S3 value file specified does not exist. %s',s3value)
       with open(file) as fp:
                properties = jprops.load_properties(fp, collections.OrderedDict);
       returncode=main(s3bucket,s3path,s3key,s3value)
       if returncode > 0:
		logging.info("Error Uploading File. Errorcode %d",returncode)
       else:
		logging.info("Succesfully uploaded file %s",s3value)
		
    else:
       logging.error('Usage: s3_upload.py <property file> <bucket> <s3 path > <key> <value file>')
       sys.exit(0)
