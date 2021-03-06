
### 按天回滚日志：
##### 新建文件 /etc/logrotate.d/nginx , 添加如下内容：
	/path/to/nginx.log
	{
		daily                 
		dateext
		rotate 30                 
		compress                   
		missingok
		#####使用 user_00账号
		# su user_00 users
		# create 644  user_00 users
		#####################
		notifempty                
		sharedscripts             
		postrotate                  
		if [ -f /path/to/nginx.pid ]
		then
			kill -USR1 `cat /path/to/nginx.pid`
		fi
		endscript                    
	}



### 按小时回滚日志
##### 1、应用场景：
	1、考虑到业务实际需求，以及一天的日志量很大，所以需要对nginx日志进行按小时切割
	2、日志一直存放，会越来越多，而磁盘空间有限，故需要定时做压缩和清理
	3、让nginx 重新生成新的日志文件，需要动态重启NGINX
 
##### 2、脚本功能：
	1、删除7天前此时的日志
	2、重命名源日志文件
	3、压缩一小时之前的日志文件（此处主要是错开 压缩日志和业务分析日志的时间）
	4、动态重启NGINX


##### 3、编辑计划任务： crontab -e 
	1 * * * * sh /data/softwares/logrotate/nginx_log_by_hours.sh >/dev/null 2>&1

##### 4、脚本内容：
	#!/bin/bash
	#cd /data/log/nginx/gamecenter

	LOG_PATH=/data/log/nginx/
	APP="cleanportal videoportal gamecenter appcenter"

	# logrotate 
	for app in $APP
	do
		if test -d $LOG_PATH/$app
		then
			cd $LOG_PATH/$app
			for i in `ls *.log`
			do
			rm -f ${i}_$(date -d '7 days ago'  "+%Y%m%d_%H").gz 
				mv $i ${i}_$(date "+%Y%m%d_%H")
			gzip  ${i}_$(date -d '1 hours ago' "+%Y%m%d_%H")
				wait
			done
		fi
	done

	# reload NGINX 
	NGINX_PID=/data/softwares/nginx/logs/nginx.pid
	if [ -f $NGINX_PID ]
	then
		kill -USR1 $(cat $NGINX_PID)

	fi
	
