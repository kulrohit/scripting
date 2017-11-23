#!/bin/bash
source properties
backupPath="/opt/database-activity"
dbfile=$2
sqlFile=${backupPath}/${dbfile}
adjSqlFilePath="/opt/database-activity/qa_only"
env=$1
addSqlFilesPath="/opt/database-activity/sqls/"
schema="${addSqlFilesPath}/schema.sql"
data="${addSqlFilesPath}/data.sql"

db_restore(){
  echo "restoring full prod dump ${dbfile} on ${dbHost} for ${dbName}"
  cd ${backupPath}
  mysql -h ${dbHost} -u ${userName} -p${password} -e "drop database ${dbName}" || exit 123
  mysql -h ${dbHost} -u ${userName} -p${password} -e "create database ${dbName}" || exit 123

  gunzip -c ${dbfile} | mysql -h ${dbHost} -u ${userName} -p${password} $dbName  || exit 123

  echo "Adjust database for non-prod usage"
  for sql in adjust.sql sandbox_companies.sql sandbox_targetkeyvalues_updated.sql
  do
    echo "Importing ${sql}" 
    mysql -h ${dbHost} -u${userName} -p${password} $dbName < ${adjSqlFilePath}/${sql} || exit 123
  done

  echo "Run schema and data sqls  on ${dbHost}"

  if [ -f "${schema}" ];then
    mysql -h ${dbHost} -u${userName} -p${password} $dbName <  ${schema}
    rm -rfv ${schema}
  else
    echo "No additional sqls"
  fi

  if [ -f "${data}" ];then
    mysql -h ${dbHost} -u${userName} -p${password} $dbName <  ${data}
    rm -rfv ${data}
  else
    echo "No additional data"
  fi
      
  echo "${dbName} ready.."
}

case $env in 
  env-name)
    userName=$stagingUserName
    password=$stagingPassword
    dbName=$stagingDbName
    db_restore
  ;;
