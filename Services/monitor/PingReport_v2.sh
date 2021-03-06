#!/bin/bash
#
# Report Ping Results : Loss  RTT: min/avg/max/mdev  
# 第一个参数：设置出口IP地址
# 第二个参数：设置监测对象IP地址
#
#

LocalIP=$( /sbin/ip -f inet addr  | grep 'scope global' | awk 'NR==1 {print $2;exit}'|sed 's@/.*@@')

INFO="Usage: ./$0 Check_Object_IP [Interface_IP]

	Interface_IP  --Default values is: $LocalIP
"

# Default argument values
CheckIP=$1
FromIP=$2

CheckIP=${CheckIP:?"$INFO"}
FromIP=${FromIP:-$LocalIP}


# Set PING  argument
Count=100
PacketSize=48
DeadLine=60
Interval=0.5

#zabbix Server 
ZABBIXSERVER=10.0.0.41
#ZABBIXREPORT=/usr/local/zabbix/bin/zabbix_sender
ZABBIXREPORT=/data/softwares/zabbix-agentd-2.2/bin/zabbix_sender

ReportInfo(){

	DesIP=$1
	Interface=$2
	#对接zabbix
	ZABBIXClient=$Interface
	# Temp data File
	DATA_FILE=pinglog-$DesIP.$$	
	echo From:$Interface  To:$DesIP

	#ping -c $Count -i $Interval -I $Interface -s $PacketSize -w $DeadLine $DesIP | awk '/packet loss/{printf("PING.loss%s %d\n",HOST,$6)}/rtt min/{split($4,v,"/");printf("PING.min%s %.2f\nPING.avg%s %.2f\nPING.max%s %.2f\nPING.mdev%s %.2f\n",HOST,v[1],HOST,v[2],HOST,v[3],HOST,v[4])}' > $DATA_FILE  HOST=$DesIP
	ping -c $Count -i $Interval -I $Interface -s $PacketSize -w $DeadLine $DesIP | awk '/rtt min/{split($4,v,"/");printf("ping.avg%s %.2f\n",HOST,v[2])}' > $DATA_FILE  HOST=$DesIP

	sed -i "s/^ping/$ZABBIXClient ping/"  ${DATA_FILE}
	## Report Data to the zabbix server
	${ZABBIXREPORT}  -z ${ZABBIXSERVER} -i ${DATA_FILE} 
	# remove the tmp  log files
	cat $DATA_FILE
	rm -f ${DATA_FILE}
	
#直接写本地本地文件
#DATA_FILE=ping-${DesIP}-PacketSize_${PacketSize}.log
#TIME="$(date +'%F %T') From:$Interface To PING:$DesIP"
#echo $TIME
#ping -c $Count -i $Interval -I $Interface -s $PacketSize -w $DeadLine $DesIP | awk '/packet loss/{printf("%s\tPING.loss %d\t",HOST,$6)}/rtt min/{split($4,v,"/");printf("PING.min %s\tPING.avg %s\tPING.max %s\tPING.mdev %s\n",v[1],v[2],v[3],v[4])}' >> $DATA_FILE  HOST="$TIME"
}

ReportInfo "$CheckIP"  "$FromIP"
