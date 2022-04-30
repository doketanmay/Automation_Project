#!/bin/bash

#Declaring variables

name="tanmay"
s3_bucket="upgrad-tanmay"

#1. Install All updates
apt update -y

#2. Check the installation of the package apache2
if [[ apache2 != $(dpkg -l apache2 | grep apache2 | awk '{print $2}') ]]
then
	apt install apache2 -y
fi

#3. Ensure that the apache2 service is running

if [[ running != $(systemctl status apache2 | grep active | awk '{print $3}' | tr -d '()') ]]
then
	systemctl start apache2
fi

#4. Ensure that the apache2 service is enabled.

if [[ enabled != $(systemctl status apache2 | grep enabled | awk '{print $4}' | tr -d ';') ]]
then
	systemctl enable apache2
fi

#5. Create a tar archive of apache2 access logs and error logs

timestamp=$(date '+%d%m%Y-%H%M%S')
cd /var/log/apache2

tar -cf /tmp/${name}-httpd-logs-${timestamp}.tar *.log

#6. Copy the archive to the s3 bucket

if [[ -f /tmp/${name}-httpd-logs-${timestamp}.tar ]]
then
	aws s3 cp /tmp/${name}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/${name}-httpd-logs-${timestamp}.tar
fi

#7. Check if inventory file is present & append new content
docpath="/var/www/html/"

if [ ! -f ${docpath}/inventory.html ]
then
	echo -e 'Log Type\t \tTime Created\t \tType\t \tSize' >${docpath}/inventory.html
fi

if [[ -f ${docpath}/inventory.html ]];
then
    size=$(du -h /tmp/${name}-httpd-logs-${timestamp}.tar | awk '{print $1}')
	echo -e "httpd-logs\t \t${timestamp}\t \ttar\t \t${size}" >> ${docpath}/inventory.html
fi

#8. Schedule Cron job to trigger script

if [ ! -f /etc/cron.d/automation ]
then
	echo "* * * * * root /root/Automation_Project/automation.sh" >> /etc/cron.d/automation
fi
