import boto
from boto.s3.connection import S3Connection
s3 = boto.connect_s3()  
buckets = s3.get_all_buckets() 
for key in buckets:
    print key.name

##Above will list the buckets name

###List the latest update file from S3 Bucket 
import boto 
c = boto.connect_s3()
bucket = c.get_bucket('mybucketname') 
bucket_files = bucket.list('subdir/file_2014_') 
l = [(k.last_modified, k) for k in bucket_files] 
key_to_download = sorted(l, cmp=lambda x,y: cmp(x[0], y[0]))[-1][1] 
key_to_download.get_contents_to_filename('target_filename')

###
