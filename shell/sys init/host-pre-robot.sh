#!/bin/bash
#
# Name:host-pre-robot.sh
# Describe:Install/uninstall itsm2 robot script
# Version:1.0
# Date:2015-12-08
# Author:Ivan Wong 
# Email:wangle-it@bestpay.com.cn
# Release:
# 2015-12-08 create
# 2015-12-31 add delete robot module
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

function install(){
SOURCE=/tmp/batch-robot.tar_$$
curl http://132.97.124.165/software/itsm/batch-robot.tar -o $SOURCE &>/dev/null
if [ $? -ne 0 ]
then
    echo "Download package fail!"
    exit 2
fi
if [ -e /opt/nimsoft ]
then
    echo "Directory '/opt/nimsoft' exist!"
    echo "Please check robot status or uninstall robot. run: $0 uninstall"
    rm -rf $SOURCE
    exit 3
fi
    $cmdpre tar -xf $SOURCE -C /opt
    IP=$($cmdpre ip a|grep inet|egrep  'bond0$|eth0$'|awk -F '[ /]' '{print $6}')
    echo "Robot IP : $IP"
    $cmdpre sed -i 's/robotip =.*/robotip = '"$IP"'/g' /opt/nimsoft/robot/robot.cfg
    $cmdpre sed -i 's/robotip =.*/robotip = '"$IP"'/g' /opt/nimsoft/robot/robot.cfx
    $cmdpre mv /opt/nimsoft/nimbus /etc/init.d/
    $cmdpre chkconfig nimbus on
    $cmdpre service nimbus start
    if [ $? -eq 0 ]
    then
        echo "Robot setup success!"
        rm -rf $SOURCE
    else
        echo "Robot setup fail!"
        echo "Please uninstall and then install robot"
        rm -rf $SOURCE
    fi
}

function uninstall(){
    if [ -e /opt/nimsoft/bin/inst_init.sh ]
    then
    $cmdpre bash /opt/nimsoft/bin/inst_init.sh remove 
    $cmdpre rm -rf /opt/nimsoft 
    echo "Robot uninstall success!"
    else
    echo "Robot is't installed!"
    fi
}

case $1 in 
'install')
    install
    ;;
'uninstall')
    uninstall
    ;;
*)
    echo "Usage : $0 [install|uninstall]"
    echo "Arg install for install itsm2 robot"
    echo "Arg install for uninstall itsm2 robot"
    exit 1
    ;;
esac