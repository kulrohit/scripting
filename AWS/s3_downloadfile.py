#!/usr/bin/env python
#Script for downloading keys from s3.
import boto
import boto.exception
from boto.s3.connection import OrdinaryCallingFormat
import jprops
import collections
import os
import sys
import logging

#Initialize logging
logging.basicConfig(format='%(asctime)s  %(levelname)s s3_downloadfile %(message)s', level=logging.INFO)

def main(s3bucket, s3prefix, localdir):
    logging.info("Downloading key prefix=%s from bucket=%s to local directory=%s",s3prefix,s3bucket,localdir)
    try:
            conn = boto.connect_s3()
            bucket = conn.get_bucket(s3bucket, validate=False)
            count=0
            for key_list in bucket.list(s3prefix):
                key = str(key_list.key)
                filename = key.split('/')[-1]
                count +=1
                key_list.get_contents_to_filename(os.path.join(localdir, filename))
                logging.info("Downloaded %s filename = %s , size=%d",count, filename, key_list.size)
            return 0
    except Exception, ex:
            print(ex.error_message)
    return 1

if __name__ == "__main__":
    if len(sys.argv) >= 4:
        file = sys.argv[1]
        if os.path.isfile(file) == False:
           raise Exception('Property filespecified does not exist.')
        with open(file) as fp:
           properties = jprops.load_properties(fp, collections.OrderedDict)
        s3bucket=sys.argv[2]
        s3prefix=sys.argv[3]
        localdir=sys.argv[4]
        returncode=main(s3bucket,s3prefix,localdir)
        if returncode > 0:
            logging.error("Error downloading keys with prefix %s",s3prefix)
    else:
       logging.error("Usage: s3download.py <property file> <bucket> <s3 prefix> <local directory>")
       sys.exit(0)
