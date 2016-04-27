#!/bin/bash
#
# Name:host-pre-vmbkroute.sh
# Describe:Set vm backup network static-route
# Version:1.0
# Date:2015-12-28
# Author:Ivan Wong 
# Email:wangle-it@bestpay.com.cn
# Release:
# 2015-12-28 Create
# 2016-01-29 add env path

#export PATH
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH

ME=$(id | awk -F '[=(]' '{print $2}')
if [ $ME -eq 0 ]
then
  cmdpre=''
else
  cmdpre='sudo '
fi
NOW=$(date +%Y%m%d%H%M)
LOCALIP=$(ip a|grep inet|egrep 'eth0$|bond0$'|awk -F'[ /]+' '{print $3}')
#disable eth1 conf gateway
$cmdpre sed -i '/^GATEWAY.*/s/^/#/g' /etc/sysconfig/network-scripts/ifcfg-eth1

#setting backup gateway static route
ip_range=${LOCALIP%.*}
case "$ip_range" in
'172.31.5')
    bak_gateway=172.30.5.254
    ;;
'172.31.6')
    bak_gateway=172.30.6.254
    ;;
'172.31.7')
    bak_gateway=172.30.7.254
    ;;
'172.31.8')
    bak_gateway=172.30.8.254
    ;;
'172.31.9')
    bak_gateway=172.30.9.254
    ;;
'172.31.10')
    bak_gateway=172.30.10.254
    ;;
'172.31.11')
    bak_gateway=172.30.11.254
    ;;
'172.31.12')
    bak_gateway=172.30.12.254
    ;;
'172.31.13')
    bak_gateway=172.30.13.254
    ;;
'172.31.14')
    bak_gateway=172.30.14.254
    ;;
*)
    echo "No match gateway!"
    exit 1;
    ;;
esac

echo "${bak_gateway%.*}.0/24 via $bak_gateway" >/tmp/route-eth1_$$
if [ -f /etc/sysconfig/network-scripts/route-eth1 ]
then
    $cmdpre cp -p /etc/sysconfig/network-scripts/route-eth1 /etc/sysconfig/network-scripts/route-eth1_bak_$NOW
fi
$cmdpre mv /tmp/route-eth1_$$ /etc/sysconfig/network-scripts/route-eth1
$cmdpre chown root:root /etc/sysconfig/network-scripts/route-eth1

$cmdpre service network restart &>/dev/null
if [ $? -eq 0 ]
then
    echo "Backup static route [ok]";
    exit 0
else
    echo "Backup static route [fail]";
    exit 2
fi

