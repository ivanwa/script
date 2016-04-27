#!/bin/bash
#
# Name:host-pre-base.sh
# Describe:Base config
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

#service
chk_stop=(NetworkManager atd bluetooth certmonger cups cpuspeed firstboot oddjobd postfix quota_nld rdisc ip6tables iptables netconsole nfs nfslock rhnsd rhsmcertd spice-vdagentd acpid autofs mdmonitor restorecond rpcgssd wdaemon saslauthd snmptrapd spice-vdagentd dnsmasq)
chk_start=(cgred cgconfig)
for i in ${chk_stop[@]}
do
    $cmdpre chkconfig $i off
done
for j in ${chk_start}
do
    $cmdpre chkconfig $j on
done
echo -e "Service init [ok]"

#sshd
$cmdpre sed -i '/^GSSAPI/s/^/#/g' /etc/ssh/sshd_config
$cmdpre sed -i '/^UseDNS/s/^/#/g' /etc/ssh/sshd_config
$cmdpre sed -i '$aUseDNS no' /etc/ssh/sshd_config
echo -e "Sshd init [ok]"

#selinux
$cmdpre setenforce 0 &>/dev/null
$cmdpre sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config &>/dev/null
echo -e "Selinux init [ok]"
exit 0
