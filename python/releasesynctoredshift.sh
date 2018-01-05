#!/usr/bin/env bash
source ./cid/var/utils/config/releasesync.conf

date=$(date +%Y%m%d)

#download files from s3
mmfile=s3://${s3_bucket}/${s3_path_type1}/multimedia-${date}.json
releasefile=s3://${s3_bucket}/${s3_path_type1}/releases-${date}.json


aws s3 cp s3://${s3_bucket}/${s3_path_type1}/multimedia-${date}.json   /cid/var/analytics/workdir/mmid/input/
aws s3 cp s3://${s3_bucket}/${s3_path_type1}/releases-${date}.json   /cid/var/analytics/workdir/mmid/input/

#Convert file to csv

python json2csv.py ${inputfile}/${mmfile} ${ouputfile}/
python json2csv.py ${inputfile}/${releasefile} ${ouputfile}/


#upload csv to s3
aws s3 cp ${outputfile}/multimedia-${date}.csv  s3://${s3_bucket}/${s3_path_type1}/${date}/processed/
aws s3 cp ${outputfile}/releases-${date}.csv  s3://${s3_bucket}/${s3_path_type2}/${date}/processed/

#dump file to redshift
export PGPASSWORD=$PGPASSWORD

psql -h ${HOST}  -U ${USERNAME} -p ${PORT} -d ${DATABASE_NAME} <<EOF

copy ${mmtable} from 's3://${s3_bucket}/${s3_path_type1}/${date}/multimedia-${date}.csv' IAM_ROLE '${IAM_ROLE}' IGNOREHEADER 1 DELIMITER ',' ;

copy ${releasestable} from 's3://${s3_bucket}/${s3_path_type2}/${date}/releases-${date}.csv' IAM_ROLE '${IAM_ROLE}' IGNOREHEADER 1 DELIMITER ',' ;

EOF