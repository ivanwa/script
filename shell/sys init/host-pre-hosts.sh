#!/bin/bash
#
# Name:host-pre-hosts.sh
# Describe:Setting hosts script
# Version:1.0
# Date:2016-01-11
# Author:Ivan Wong 
# Email:wangle-it@bestpay.com.cn
# Release:
# 2016-01-11 create
# 2016-01-29 add env path

#export PATH
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH

LOCALIP=$(ip a|grep inet|egrep 'eth0$|bond0$'|awk -F'[ /]+' '{print $3}')
NOW=$(date +%Y%m%d%H%M)
HOSTNAME=$(hostname)
sudo mv /etc/hosts /etc/hosts_bak_$NOW
echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" >/tmp/hosts_$$
echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >>/tmp/hosts_$$
echo "$LOCALIP    $HOSTNAME" >>/tmp/hosts_$$
sudo mv /tmp/hosts_$$ /etc/hosts
sudo chmod 644 /etc/hosts
sudo chown root:root /etc/hosts
cat /etc/hosts
