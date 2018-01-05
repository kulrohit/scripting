#!/bin/bash
SCRIPT_RETURNCODE=0

#NAME_JAVA_OPTS={{NAME_JAVA_OPTS}}
#NAME_SERVER={{NAME_SERVER}}
#WTEANALYTICS_BUCKETNAME={{TA_S3_BUCKET}}
#WTEANALYTICS_BUCKETFOLDER={{LASTRUN_BUCKET_PATH}}
#
#SFTP_MAX_RETRIES=3
#SFTP_RETRY_WAIT_INTERVAL=5
#SFTP_FLAGS="-oBatchMode=no -b - -oStrictHostKeyChecking=no -oPort="
#SFTP_PORT={{NAME_SFTP_PORT}}
#
#NAMEFTP_USERNAME={{NAMEFTP_USERNAME}}
#NAMEFTP_PASSWORD={{NAMEFTP_PASSWORD}}
#NAME_LOCALDIR={{NAME_LOCALDIR}}
#NAME_REMOTEDIR={{NAME_REMOTEDIR}}
# Source the config file to get the list of servers to ftp the files
#. ./ysftp.config

. /opt/appvar/app-name/config/name.conf
LOG_FILE="/opt/applogs/app-name/name.log"

# Funtion for standardised Script logging
f_log()
{
  echo -e "`date` - $1" >> $LOG_FILE
}

# Function for sftp
f_sftp()
{
sftp_server=$1
SFTP_RETRY_COUNT=0
while [ $SFTP_RETRY_COUNT != $SFTP_MAX_RETRIES ]
do

f_log "Start file transfer to Liverramp Server "
export SSHPASS=$NAMEFTP_PASSWORD
sshpass -e sftp  ${SFTP_FLAGS}${SFTP_PORT} $NAMEFTP_USERNAME@$NAME_SERVER <<!
   cd $1
   mput $2
   ls -ltr $SFTP_LOCALFILE
   bye
!
return_code=$?

if [ $return_code == 0 ]
then
  f_log "Succesful file transfer to $sftp_server file $SFTP_LOCALDIR/$SFTP_LOCALFILE"  
  SFTP_RETRY_COUNT=$SFTP_MAX_RETRIES
else
  # check if return code is 255 then retry. 
  if [ $return_code == 255 ]
  then    
    SFTP_RETRY_COUNT=$[$SFTP_RETRY_COUNT+1]
          f_log "Retry SFTP Connection - count = $SFTP_RETRY_COUNT "
          sleep $SFTP_RETRY_WAIT_INTERVAL
      if [ $SFTP_RETRY_COUNT == $SFTP_MAX_RETRIES ]
                        then
                                f_log "Maximum retires reached "
        SCRIPT_RETURNCODE=1
                        fi
  else 
    f_log "[error] File transfer to $sftp_server file $SFTP_LOCALDIR/$SFTP_LOCALFILE failed returncode=$return_code"
    SFTP_RETRY_COUNT=$SFTP_MAX_RETRIES
    SCRIPT_RETURNCODE=1
  fi

fi
done
}

# MAIN
f_log "Starting file trasfer."
f_sftp $1 $2
f_log "File trasnfer completed ."
exit $SCRIPT_RETURNCODE




