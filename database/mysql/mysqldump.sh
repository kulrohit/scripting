#!/bin/bash
LDIR=`dirname $0`
SCRIPT_RETURNCODE=0
# Source the config file to get the list of servers to ftp the files
. $LDIR/ymysqldump.config

# Funtion for standardised Script logging
f_log()
{
	echo -e "`date` - $1" 
}


# MAIN
f_log "Starting mysql sync..."
OUTPUT_FILE=`date +'%y%m%d%H%M'`
OUTPUT_FILE="$DATA_DIR/mysqldump_$OUTPUT_FILE"

mysqldump --host=$SOURCE_MYSQL_HOST --port=$SOURCE_MYSQL_PORT --user=$SOURCE_MYSQL_USERNAME --password=$SOURCE_MYSQL_PASSWORD $SOURCE_MYSQL_DATABASE $SOURCE_MYSQL_DATABASE_TABLES >> $OUTPUT_FILE
rc=$?

if [ $rc -eq 0 ] 
	then 
	f_log "INFO:MySql Backup completed"
	exit 0
esle
	f_log "ERROR: $rc , Backup not completed"
	exit 1
fi
