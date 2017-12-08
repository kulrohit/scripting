#!/bin/bash
SCRIPT_RETURNCODE=0
# Source the config file to get the list of servers to ftp the files
. ./ysftp.config

# Funtion for standardised Script logging
f_log()
{
	echo -e "`date` - $1" 
}

# Function for sftp
f_sftp()
{
sftp_server=$1
SFTP_RETRY_COUNT=0
while [ $SFTP_RETRY_COUNT != $SFTP_MAX_RETRIES ]
do

f_log "Start file transfer to $sftp_server file $SFTP_LOCALDIR/$SFTP_LOCALFILE"
sftp $SFTP_FLAGS  $sftp_server << !
   cd $SFTP_RDIR
   put $SFTP_LOCALDIR/$SFTP_LOCALFILE 
   ls -ltr $SFTP_LOCALFILE
   !ls -ltr $SFTP_LOCALDIR/$SFTP_LOCALFILE
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
for server in $SFTP_SERVER_LIST
do
 f_sftp $server 
done
exit $SCRIPT_RETURNCODE
