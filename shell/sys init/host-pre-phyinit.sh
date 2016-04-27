#!/bin/bash
#
# Name:host-pre-phyinit.sh
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

#define IP
checkip=132.97.124.165
function check_network(){
	curl -I -s --connect-timeout 3 http://$checkip &>/dev/null
	if [ $? -ne 0 ]
	then
		echo "Yum repo connection fail"
		exit 3
	fi
}
function base_init(){
	curl  http://${checkip}/script/host-pre-base.sh -o /tmp/base_$$.sh &>/dev/null
	bash /tmp/base_$$.sh&&rm -rf /tmp/base_$$.sh
}
function yum_init(){
	curl  http://${checkip}/script/host-pre-yum.sh -o /tmp/yum_$$.sh &>/dev/null
	bash /tmp/yum_$$.sh product&&rm -rf /tmp/yum_$$.sh
}
function pip_init(){
	curl  http://${checkip}/script/host-pre-pip.sh -o /tmp/pip_$$.sh &>/dev/null
	bash /tmp/pip_$$.sh product&&rm -rf /tmp/pip_$$.sh
}
function software_init(){
	curl  http://${checkip}/script/host-pre-baserpm.sh -o /tmp/baserpm_$$.sh &>/dev/null
	bash /tmp/baserpm_$$.sh&&rm -rf /tmp/baserpm_$$.sh
}
function snmpd_init(){
	curl  http://${checkip}/script/host-pre-snmpd.sh -o /tmp/snmpd_$$.sh &>/dev/null
	bash /tmp/snmpd_$$.sh install&&rm -rf /tmp/snmpd_$$.sh
}
function robot_init(){
	curl  http://${checkip}/script/host-pre-robot.sh -o /tmp/robot_$$.sh &>/dev/null
	bash /tmp/robot_$$.sh install&&rm -rf /tmp/robot_$$.sh
}
function extra_init(){
	curl  http://${checkip}/script/host-pre-extra.sh -o /tmp/extra_$$.sh &>/dev/null
	bash /tmp/extra_$$.sh&&rm -rf /tmp/extra_$$.sh
}
function baseline_init(){
	curl  http://${checkip}/script/security_script_v2.sh -o /tmp/baseline_$$.sh &>/dev/null
	bash /tmp/baseline_$$.sh set&&rm -rf /tmp/baseline_$$.sh
}

function clean(){
	rm -rf /tmp/base_$$.sh      &>/dev/null
	rm -rf /tmp/yum_$$.sh       &>/dev/null
	rm -rf /tmp/pip_$$.sh       &>/dev/null
	rm -rf /tmp/baserpm_$$.sh   &>/dev/null
	rm -rf /tmp/snmpd_$$.sh     &>/dev/null
    rm -rf /tmp/robot_$$.sh     &>/dev/null
    rm -rf /tmp/extra_$$.sh     &>/dev/null
    rm -rf /tmp/baseline_$$.sh  &>/dev/null
}

check_network
base_init
yum_init
pip_init
software_init
snmpd_init
robot_init
extra_init
baseline_init
clean
