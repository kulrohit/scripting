#!/usr/bin/env bash

ZABBIX_SERVER="10.44.2.165"
STARTTIME=`date -d "-5 minutes" "+%Y-%m-%dT%H:%M:%SZ"`
ENDTIME=`date -d "-4 minutes" "+%Y-%m-%dT%H:%M:%SZ"`
echo $STARTTIME
echo $ENDTIME


#UnHealthyHostCount
UHCOUNT=$(aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name UnHealthyHostCount --statistics Average  --period 3600 --dimensions Name=LoadBalancer,Value=app/yourelb/8c49a84f5593b792 Name=TargetGroup,Value=targetgroup/yourtarget/5c972f92881a52b4 --start-time ${STARTTIME} --end-time ${ENDTIME} --output text | tail -1 | awk '{printf("%d\n",$2 + 0.5)}')

/usr/bin/zabbix_sender -z ${ZABBIX_SERVER} -s yourelb -k UnHealthyHostCount.key -o ${UHCOUNT}


HCOUNT=$(aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HealthyHostCount --statistics Average  --period 3600 --dimensions Name=LoadBalancer,Value=app/yourelb/8c49a84f5593b792 Name=TargetGroup,Value=targetgroup/yourtarget/5c972f92881a52b4 --start-time ${STARTTIME} --end-time ${ENDTIME} --output text | tail -1 | awk '{printf("%d\n",$2 + 0.5)}')

/usr/bin/zabbix_sender -z ${ZABBIX_SERVER} -s yourelb -k HealthyHostCount.key -o ${HCOUNT}

#HTTPCode_Target_2XX_Count
HTTPCode_Target_2XX_Count=$(aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_Target_2XX_Count --statistics Sum  --period 3600 --dimensions Name=LoadBalancer,Value=app/yourelb/8c49a84f5593b792 Name=TargetGroup,Value=targetgroup/yourtarget/5c972f92881a52b4 --start-time ${STARTTIME} --end-time ${ENDTIME} --output text | tail -1 | awk '{printf("%d\n",$2 + 0.5)}')

/usr/bin/zabbix_sender -z ${ZABBIX_SERVER} -s yourelb -k HTTPCode_Target_2XX_Count.key -o ${HTTPCode_Target_2XX_Count}

#HTTPCode_Target_3XX_Count
HTTPCode_Target_3XX_Count=$(aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_Target_3XX_Count --statistics Sum  --period 3600 --dimensions Name=LoadBalancer,Value=app/yourelb/8c49a84f5593b792 Name=TargetGroup,Value=targetgroup/yourtarget/5c972f92881a52b4 --start-time ${STARTTIME} --end-time ${ENDTIME} --output text | tail -1 | awk '{printf("%d\n",$2 + 0.5)}')

/usr/bin/zabbix_sender -z ${ZABBIX_SERVER} -s yourelb -k HTTPCode_Target_3XX_Count.key -o ${HTTPCode_Target_3XX_Count}

#HTTPCode_Target_4XX_Count
HTTPCode_Target_4XX_Count=$(aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_Target_4XX_Count --statistics Sum  --period 3600 --dimensions Name=LoadBalancer,Value=app/yourelb/8c49a84f5593b792 Name=TargetGroup,Value=targetgroup/yourtarget/5c972f92881a52b4 --start-time ${STARTTIME} --end-time ${ENDTIME} --output text | tail -1 | awk '{printf("%d\n",$2 + 0.5)}')

/usr/bin/zabbix_sender -z ${ZABBIX_SERVER} -s yourelb -k HTTPCode_Target_4XX_Count.key -o ${HTTPCode_Target_4XX_Count}

#HTTPCode_ELB_2XX_Count
HTTPCode_ELB_2XX_Count=$(aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_ELB_2XX_Count --statistics Sum  --period 3600 --dimensions Name=LoadBalancer,Value=app/yourelb/8c49a84f5593b792 Name=TargetGroup,Value=targetgroup/yourtarget/5c972f92881a52b4 --start-time ${STARTTIME} --end-time ${ENDTIME} --output text | tail -1 | awk '{printf("%d\n",$2 + 0.5)}')

/usr/bin/zabbix_sender -z ${ZABBIX_SERVER} -s yourelb -k HTTPCode_ELB_2XX_Count.key -o ${HTTPCode_ELB_2XX_Count}

#HTTPCode_ELB_3XX_Count
HTTPCode_ELB_3XX_Count=$(aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_ELB_3XX_Count --statistics Sum  --period 3600 --dimensions Name=LoadBalancer,Value=app/yourelb/8c49a84f5593b792 Name=TargetGroup,Value=targetgroup/yourtarget/5c972f92881a52b4 --start-time ${STARTTIME} --end-time ${ENDTIME} --output text | tail -1 | awk '{printf("%d\n",$2 + 0.5)}')

/usr/bin/zabbix_sender -z ${ZABBIX_SERVER} -s yourelb -k HTTPCode_ELB_3XX_Count.key -o ${HTTPCode_ELB_3XX_Count}

#HTTPCode_ELB_4XX_Count
HTTPCode_ELB_3XX_Count=$(aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_ELB_4XX_Count --statistics Sum  --period 3600 --dimensions Name=LoadBalancer,Value=app/yourelb/8c49a84f5593b792 Name=TargetGroup,Value=targetgroup/yourtarget/5c972f92881a52b4 --start-time ${STARTTIME} --end-time ${ENDTIME} --output text | tail -1 | awk '{printf("%d\n",$2 + 0.5)}')

/usr/bin/zabbix_sender -z ${ZABBIX_SERVER} -s yourelb -k HTTPCode_ELB_4XX_Count.key -o ${HTTPCode_ELB_4XX_Count}

#HTTPCode_ELB_5XX_Count
HTTPCode_ELB_3XX_Count=$(aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_ELB_5XX_Count --statistics Sum  --period 3600 --dimensions Name=LoadBalancer,Value=app/yourelb/8c49a84f5593b792 Name=TargetGroup,Value=targetgroup/yourtarget/5c972f92881a52b4 --start-time ${STARTTIME} --end-time ${ENDTIME} --output text | tail -1 | awk '{printf("%d\n",$2 + 0.5)}')

/usr/bin/zabbix_sender -z ${ZABBIX_SERVER} -s yourelb -k HTTPCode_ELB_5XX_Count.key -o ${HTTPCode_ELB_5XX_Count}


#RequestCount 
RCSUM=$(aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name RequestCount --statistics Sum  --period 3600 --dimensions Name=LoadBalancer,Value=app/yourelb/8c49a84f5593b792 Name=TargetGroup,Value=targetgroup/yourtarget/5c972f92881a52b4 --start-time ${STARTTIME} --end-time ${ENDTIME} --output text | tail -1 | awk '{printf("%d\n",$2 + 0.5)}')

/usr/bin/zabbix_sender -z ${ZABBIX_SERVER} -s yourelb -k RequestCount.key -o ${RCSUM}


#LATENCY
Latency=$(aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name TargetResponseTime --statistics Average --period 3600 --dimensions Name=LoadBalancer,Value=app/yourelb/8c49a84f5593b792 Name=TargetGroup,Value=targetgroup/yourtarget/5c972f92881a52b4 --start-time ${STARTTIME} --end-time ${ENDTIME} --output text | tail -1 | awk '{printf("%d\n",$2 + 0.5)}')

/usr/bin/zabbix_sender -z ${ZABBIX_SERVER} -s yourelb -k Latency.key -o ${Latency}

#LATENCY
Latency=$(aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name TargetResponseTime --statistics Average --period 3600 --dimensions Name=LoadBalancer,Value=app/NDP21LB01/8c49a84f5593b792 Name=TargetGroup,Value=targetgroup/yourtarget/5c972f92881a52b4 --start-time ${STARTTIME} --end-time ${ENDTIME} --output text | tail -1 | awk '{printf("%d\n",$2 + 0.5)}')

/usr/bin/zabbix_sender -z ${ZABBIX_SERVER} -s NDP21LB01 -k Latency.key -o ${Latency}