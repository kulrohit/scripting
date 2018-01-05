#!/bin/bash
# Source the config file to get the list of servers to ftp the files

. /cid/software/utils/CID-150-SNAPSHOT/bin/mmidsync.conf 
LOG_FILE="/cid/log/analytics/ftp.log"
date=$(date +%Y%m%d)
yesterdaydate=$(date +%Y%m%d --date "1 days ago")
#yesterdaydate=$(date -v-1d +%Y%m%d) ##for MAC

# Funtion for standardised Script logging
applog()
{
  echo -e "`date` - $1" >> $LOG_FILE
}

# Function for sftp
c_sftp()
{
sftp_server=$1
SFTP_RETRY_COUNT=0
while [ $SFTP_RETRY_COUNT != '3' ]
do

applog "Start file transfer to Server "
export SSHPASS=$sftp_pass
sshpass -e sftp  ${sftp_flag} $sftp_user@$sftp_host<<!
   mget *$yesterdaydate* $source_path
   ls -ltr $source_path
   bye
!
return_code=$?

if [ $return_code == 0 ]
then
  applog "Succesful file transfer from $sftp_host file to $source_path"  
  SFTP_RETRY_COUNT=$SFTP_MAX_RETRIES
else
  # check if return code is 255 then retry. 
  if [ $return_code == 255 ]
  then    
    SFTP_RETRY_COUNT=$[$SFTP_RETRY_COUNT+1]
          applog "Retry SFTP Connection - count = $SFTP_RETRY_COUNT "
          sleep $SFTP_RETRY_WAIT_INTERVAL
      if [ $SFTP_RETRY_COUNT == $SFTP_MAX_RETRIES ]
          then
            applog "Maximum retires reached "
            SCRIPT_RETURNCODE=1
      fi
  else 
    applog "[error] File transfer to $sftp_server file $SFTP_LOCALDIR/$SFTP_LOCALFILE failed returncode=$return_code"
    SFTP_RETRY_COUNT=$SFTP_MAX_RETRIES
    SCRIPT_RETURNCODE=1
  fi

fi
done
}

# MAIN
applog "Starting file trasfer."
c_sftp 
applog "File trasnfer completed ."
exit $SCRIPT_RETURNCODE
