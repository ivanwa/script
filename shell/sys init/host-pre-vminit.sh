#!/bin/bash
#
# Name:host-pre-pyhinit.sh
# Describe:Physical system init script
# Version:1.0
# Date:2015-11-26
# Author:Ivan Wong 
# Email:wangle-it@bestpay.com.cn
# Release:
# 2015-11-26 create
# 2016-01-29 add env path

#export PATH
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH


checkip=132.97.124.165
function check_network(){
	curl -I -s --connect-timeout 3 http://$checkip &>/dev/null
	if [ $? -ne 0 ]
	then
		echo "Yum repo connection fail"
		exit 3
	fi
}
function hosts_init(){
	curl  http://${checkip}/script/host-pre-hosts.sh -o /tmp/hosts_$$.sh &>/dev/null
	bash /tmp/hosts_$$.sh&&rm -rf /tmp/hosts_$$.sh
}
function bakroute_init(){
	curl  http://${checkip}/script/host-pre-vmbkroute.sh -o /tmp/bakroute_$$.sh &>/dev/null
	bash /tmp/bakroute_$$.sh $env&&rm -rf /tmp/bakroute_$$.sh
}
function snmpd_init(){
	curl  http://${checkip}/script/host-pre-snmpd.sh -o /tmp/snmpd_$$.sh &>/dev/null
	bash /tmp/snmpd_$$.sh install&&rm -rf /tmp/snmpd_$$.sh
}
function robot_init(){
	curl  http://${checkip}/script/host-pre-robot.sh -o /tmp/robot_$$.sh &>/dev/null
	bash /tmp/robot_$$.sh install&&rm -rf /tmp/robot_$$.sh
}


function clean(){
	rm -rf /tmp/hosts_$$.sh &>/dev/null
	rm -rf /tmp/bakroute_$$.sh &>/dev/null
	rm -rf /tmp/snmpd_$$.sh &>/dev/null
    rm -rf /tmp/robot_$$.sh &>/dev/null
}

#MAIN
check_ip
check_network
hosts_init
bakroute_init
snmpd_init
robot_init
clean

