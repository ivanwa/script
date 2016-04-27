#!/bin/bash
#
# Name:host-pre-snmpd.sh
# Describe:Snmpd config
# Version:1.0
# Date:2015-12-14
# Author:Ivan Wong 
# Email:wangle-it@bestpay.com.cn
# Release:
# 2015-12-14 create
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

#IP
localip=$(ip a|grep inet|egrep  'bond0$|eth0$'|awk -F '[ /]' '{print $6}')

#curry date
now=$(date +%Y%m%d%H%M)

function snmpd_check(){
rpm -q expect &>/dev/null
rpm1=$?
rpm -q net-snmp &>/dev/null
rpm2=$?
if [ $rpm1 -eq 0 -a $rpm2 -eq 0 ]
then
    return 0
else
    $cmdpre yum install net-snmp expect -y &>/dev/null
    if [ $? -ne 0 ]
    then
        echo "Snmpd package install [fail]"
        echo "Snmpd init [fail]"
        exit 1
    else
        echo "Snmpd package install [ok]"
        return 0
    fi
fi
}

function snmpd_init(){
local TEAM_NUM=$(mkpasswd -s 0 -l 12)
$cmdpre mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf_bak_$now
cat >/tmp/snmpd.conf_$$<<EOF
com2sec itsm           default       $TEAM_NUM
group   notConfigGroup v1           notConfigUser
group   MyROGroup      v2c          itsm
group   notConfigGroup v2c           notConfigUser
view    systemview    included   .1.3.6.1.2.1
view    systemview    included   .1.3.6.1.2.1.1
view    systemview    included   .1.3.6.1.4.1
view    systemview    included   .1.3.6.1.2.1.25
view    systemview    included   .1.3.6.1.2.1.25.1.1
access  MyROGroup      ""      any       noauth    exact  systemview none none
access  notConfigGroup ""      any       noauth    exact  systemview none none
syslocation Unknown (edit /etc/snmp/snmpd.conf)
syscontact Root <root@localhost> (configure /etc/snmp/snmp.local.conf)
dontLogTCPWrappersConnects yes
EOF
$cmdpre mv /tmp/snmpd.conf_$$ /etc/snmp/snmpd.conf
$cmdpre chown root:root /etc/snmp/snmpd.conf
$cmdpre service snmpd restart &>/dev/null
$cmdpre chkconfig snmpd on &>/dev/null
echo "Snmpd init [ok]"
}

function get_teamnum(){
    local NUM=$($cmdpre egrep "com2sec[[:space:]]*itsm" /etc/snmp/snmpd.conf|awk '{print $4}')
    echo "${localip},TeamNumber,${NUM}"
    exit 0
}

##main
case $1 in 
    install)
        snmpd_check
        snmpd_init
        get_teamnum
        ;;
    show)
        get_teamnum
        ;;
    *)
        echo "Usage: $0 [install|show]"
        echo -e "$0 install\nConfigure snmpd,include itsm team number."
        echo -e "$0 show\nShow current configuration itsm team number."
        exit 2
        ;;
esac

