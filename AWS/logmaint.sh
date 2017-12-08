#!/bin/bash
#script to find old log files of given age & delete them
log_file=/opt/wfxlogs/wfxutil/logmaint_`date +%Y%m%d`.log

# Funtion for standardised Script logging
f_log()
{
        echo -e "`date` - $1" | tee -a $log_file
}

# check for logmaint.conf parameter
if [ "$#" -gt 0 ];then
	CONF_FILE=$1
else
	CONF_FILE='/opt/wfxvar/wfxutil/config/logmaint.conf'
fi

if [ ! -f ${CONF_FILE} ]; then 
	f_log " Configuration file ${CONF_FILE} does not exist. Exiting..."
	exit 1
fi



#check given path and count value in logmaint.conf file to delete file(s), one by one 

f_log "Starting Log File maintenance."

for i in `cat  $CONF_FILE`
do
        path=$(echo ${i} |  sed 's/,/ /g' | awk '{print $1}')         # get path from logmaint.conf
        count=$(echo ${i} |  sed 's/,/ /g' | awk '{print $2}')        # get day(s) value from logmaint.conf
        find ${path} -type f -mtime +${count}   2>/dev/null           # check the existance of file(s) before delete
        if [ $? == 1 ]; then
	        f_log "No file(s) to delete on path $path " 
        else
       		find ${path} -type f -mtime +${count} -delete
       		f_log "Successfully deleted $count day(s) old file(s) from path $path"
        fi
done

f_log "Completed Log File maintenance."
