#!/bin/bash
CID_LOG=/cid/log/analytics
CID_VAR=/cid/var/analytics
#CID_CONF=$CID_VAR/config/$1/mmidsync.conf
CID_CONF=/cid/opt/utils/bin/mmidsync.conf
#CID_CONF=$1
CID_UTILS=/cid/opt/utils
CID_HOME=/cid/opt/analytics

date=$(date +%Y%m%d)
yesterdaydate=$(date +%Y%m%d --date "1 days ago")
logdate=$(date +%Y-%m-%d)
LOG_FILE=$CID_LOG/mmidsync_run_${logdate}.log

applog()
{
echo -e "`date` - $1" >> $LOG_FILE
}

applog "INFO: Starting MMID Sync to S3"
if [ $# -ge 1 ]; then
        CID_CONF=$1
fi

#Check for existence of property file
if [ ! -f $CID_CONF ]; then
        applog "ERROR:  property file ${CID_CONF}} does not exist. "
        exit 1;
else
        # Source the file to use environment specific configuraiton information
        . $CID_CONF
fi

##### CLEANING SOURCE AND DESTINATION DIRECTORY ######
applog "INFO: Cleaning up source and destination directory"
#rm -r ${source_path}/*.log.gz ${dest_path}/*.csv

##### DOWNLOAD FILES FROM SFTP SERVER #####
applog "INFO: Connecting to sftp server"
#sshpass -p ${sftp_pass} sftp -P22 ${sftp_user}@${sftp_host}:{sftp_dir_path} << !
#$CID_UTILS/bin/cision_ftp.sh

##### READ ORACLE LOG FILES AND TRANSFORM TO CSV ######
applog "INFO: Parsing logs and preparing csv files"
echo ${yesterdaydate}
python $CID_HOME/bin/mediamathid_sync2redshift.py -d ${yesterdaydate} -l ${source_path} -c ${dest_path}

##### FIND FILES FOR DATE AND UPLOAD TO S3 ######
applog "INFO: Fetching csv files to upload to S3"
for file in `find ${dest_path} -type f -name \*$yesterdaydate\*.csv`
do
	echo $file
	gzip $file
	filename=$(basename $file)
	applog "INFO: Uploading ${filename}.gz to S3"
	aws s3 cp ${file}.gz s3://${s3_bucket}/${s3_path}/${date}/${filename}.gz
	retval=$?
	if [ "$retval" != 0 ]
	then
		applog "ERROR: S3 Upload failed for file ${filename}.gz"
		gunzip ${file}.gz
		exit 1;
	fi
done
applog "INFO: Completed MMID Sync to S3"

##### SYNC TO REDSHIFT ######
python $CID_UTILS/bin/copy_s3toredshift.py $CID_CONF
##Reusing 
