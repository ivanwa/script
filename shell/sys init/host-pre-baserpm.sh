#!/bin/bash
#
# Name:host-pre-baserpm.sh
# Describe:Base software config
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

$cmdpre yum install -y vim vim-enhanced bash-completion lrzsz lsof expect nc telnet pciutils bind-utils strace ltrace tcpdump iotop unzip lftp sysstat wget blktrace man man-pages lsscsi  net-snmp ntp sysfsutils dropwatch automake autoconf libtool vsftpd python-devel gcc gcc-c++ glibc glibc-common glibc-devel glibc-headers dsniff iftop nethogs nmon tuned lm_sensors   sg3_utils binutils elfutils-libelf elfutils-libelf-devel libaio libaio-devel libgcc libstdc++ libstdc++-devel unixODBC unixODBC-devel compat-libcap1 ksh compat-libstdc++* readline*  &>/dev/null
if [ $? -eq 0 ]
then
	echo -e "Base software init [ok]"
	exit 0
else
	echo -e "Base software init [fail]"
	exit 1
fi
