#!/bin/bash
#
# Name:host-pre-extra.sh
# Describe:Extra config
# Version:1.0
# Date:2015-11-22
# Author:Ivan Wong 
# Email:wangle-it@bestpay.com.cn
# Release:
# 2015-11-22 create
# 2016-01-29 add env path

#export PATH
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH

me=$(id | awk -F '[=(]' '{print $2}')
if [ $me -eq 0 ]
then
  cmdpre=''
else
  cmdpre='sudo '
fi

#System update
echo -e "System updating..."
$cmdpre yum update -y &>/dev/null
if [ $? -eq 0 ]
then
echo -e "System update [ok]"
else
echo -e "System update [fail]"
fi

#Partition setting
$cmdpre chown bestpay:bestpay /data  &>/dev/null
$cmdpre chmod 0750 /data             &>/dev/null
$cmdpre chown bestpay:bestpay /tools &>/dev/null
$cmdpre chmod 0700 /tools            &>/dev/null
$cmdpre mkdir /itsm                  &>/dev/null
$cmdpre chown itsm:itsm /itsm        &>/dev/null
$cmdpre chmod 0700 /itsm             &>/dev/null
echo -e "Partition setting [ok]"
exit 0
