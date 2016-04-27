#!/bin/bash
#
# Name:host-pre-pip.sh
# Describe:Pip repo config
# Version:1.1
# Date:2015-8-17
# Author:Ivan Wong 
# Email:wangle-it@bestpay.com.cn
# Release:
# 2015-8-17 create
# 2015-11-22 change test IP
# 2016-01-29 add env path

#export PATH
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH

case $1 in 
test)
	ip='172.26.10.59'
	;;
product)
	ip='132.97.124.165'
	;;
*)
	echo "Usage: $0 [test|product]"
	exit 1
	;;
esac
me=$(id | awk -F '[=(]' '{print $2}')
if [ $me -eq 0 ]
then
  cmdpre=''
else
  cmdpre='sudo '
fi
if [ ! -d /root/.pip  ]
then
	sudo mkdir -p /root/.pip
fi
cat >/tmp/pip.conf_$$  <<EOF
[global]
index-url = http://$ip/pypi/web/simple
[install]
trusted-host = $ip
EOF
sudo mv /tmp/pip.conf_$$ /root/.pip/pip.conf
sudo chown root:root /root/.pip/pip.conf
echo "Pip config [ok]!"
echo "Installing pip..."
sudo yum install python-pip -y &>/dev/null
if [ $? -eq 0 ]
then
	echo "Pip install [ok]"
	exit 0
else
	echo "Pip install [fail].Please check yum config"
	exit 1
fi

