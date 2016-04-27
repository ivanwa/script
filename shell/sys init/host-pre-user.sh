#!/bin/bash
# Name: host-pre-user.sh
# Describe: bestpay sys user tools
# Version:1.0
# Date:2016-01-11
# Author:Ivan Wong 
# Email:wangle-it@bestpay.com.cn
# Release:
# 2016-01-11 create
# 2016-01-29 add env path,unchange root user

#export PATH
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH

#who are you
ME=$(id | awk -F '[=(]' '{print $2}')
if [ $ME -eq 0 ]
then
  cmdpre=''
else
  cmdpre='sudo '
fi

#IP
LOCALIP=$(ip a|grep inet|egrep  'bond0$|eth0$'|awk -F '[ /]' '{print $6}')

#curry date
NOW=$(date +%Y%m%d%H%M)

#username define
users=(
#root
maintain
yuchuli
itsm
bestpay
logview
)
orausers=(
oracle
grid
)
#oracle user 
create_grid=0
if [[ $2 == 'enracuser' ]]
then
	create_grid=1
fi


#check expect installed
function checkRpm(){
  rpm -q expect &>/dev/null
  if [ $? -eq 0 ]
  then
    return 0;
  else
	echo "Package expect isn't install"
	echo "Package expect installing"
	yum install -y expect &>/dev/null
	if [ $? -eq 0 ]
	then
	  echo "Package expect install successful"
	  return 0;
	else
	  echo "Package expect install fail"
	  exit 1;
	fi
  fi   
}

#create user
function createUsers(){
  $cmdpre cp -p /etc/passwd /etc/passwd_bak_$NOW
  $cmdpre cp /etc/group /etc/group_bak_$NOW
  for user in ${users[@]}; 
  do
    $cmdpre grep $user /etc/passwd &>/dev/null
    if [ $? -ne 0 ]
    then
        case "$user" in
        maintain)
            uid=1501
            gid=1501
            ;;
        yuchuli)
            uid=1502
            gid=1502
            ;;
        bestpay)
            uid=1503
            gid=1503
            ;;
        logview)
            uid=1504
            gid=1504
            ;;
        itsm)
            uid=1505
            gid=1505
            ;;
        esac
        $cmdpre groupadd -g $gid $user   &>/dev/null
        $cmdpre useradd -u $uid -g $user $user   &>/dev/null
        $cmdpre chage -M 99999 $user     &>/dev/null
        if [[ $user == logview && $user == itsm  ]]
        then
            $cmdpre usermod -a -G bestpay $user  &>/dev/null
        fi
    fi
  done
  if [ $create_grid -eq 1  ];
  then
    $cmdpre groupadd -g 1000 oinstall    &>/dev/null
    $cmdpre groupadd -g 1200 asmadmin    &>/dev/null
    $cmdpre groupadd -g 1201 asmdba      &>/dev/null
    $cmdpre groupadd -g 1202 asmoper     &>/dev/null
    $cmdpre groupadd -g 1300 dba         &>/dev/null
    $cmdpre groupadd -g 1301 oper        &>/dev/null
    $cmdpre useradd -u 1100 -g oinstall -G asmadmin,asmdba,asmoper grid     &>/dev/null
    $cmdpre useradd -u 1101 -g oinstall -G dba,oper,asmdba oracle           &>/dev/null
    $cmdpre chage -M 99999 grid          &>/dev/null
    $cmdpre chage -M 99999 oracle        &>/dev/null
  else
    $cmdpre groupadd -g 1000 oinstall     &>/dev/null
    $cmdpre groupadd -g 1300 dba          &>/dev/null
    $cmdpre groupadd -g 1301 oper         &>/dev/null
    $cmdpre useradd -u 1101 -g oinstall -G dba,oper oracle  &>/dev/null
    $cmdpre usermod -a -G oinstall bestpay  &>/dev/null
    $cmdpre chage -M 99999 oracle         &>/dev/null
  fi
}

#change passwd
function chPasswd(){
  $cmdpre cp -p /etc/shadow /etc/shadow_bak_$NOW
  for user in ${users[@]};
  do
    $cmdpre grep $user /etc/passwd &>/dev/null
    if [ $? -eq 0 ]
    then
      password=$(mkpasswd -s 0 -l 12)
      echo $password|$cmdpre passwd --stdin $user &>/dev/null
      echo "${LOCALIP},${user},${password}"
    fi
  done
  for orauser in ${orausers[@]};
  do
    $cmdpre grep $orauser /etc/passwd &>/dev/null
    if [ $? -eq 0 ]
    then
    password=$(mkpasswd -s 0 -l 12)
    echo $password|$cmdpre passwd --stdin $orauser &>/dev/null
    echo "${LOCALIP},${orauser},${password}"
    fi 
  done
}

#sudo setting
function sudoConfig(){
  $cmdpre cp -p /etc/sudoers /etc/sudoers_bak_$NOW
  $cmdpre sed -i 's/^Defaults    requiretty/#Defaults    requiretty/g' /etc/sudoers
  if [ ! -e /etc/sudoers.d/syssudo ]
  then
    $cmdpre sed -i '/^Defaults[[:space:]]*logfile[[:space:]]*=/s/^/#/g' /etc/sudoers
    echo 'Defaults logfile=/var/log/sudo.log' > /tmp/syssudo_$$
    $cmdpre mv /tmp/syssudo_$$ /etc/sudoers.d/syssudo
    $cmdpre chmod 440 /etc/sudoers.d/syssudo
    $cmdpre chown root:root /etc/sudoers.d/syssudo
    #$cmdpre sed -i '$aDefaults logfile=\/var\/log\/sudo.log' /etc/sudoers
    $cmdpre sed -i '/^Defaults[[:space:]]*loglinelen[[:space:]]*=/s/^/#/g' /etc/sudoers
    $cmdpre sed -i '$aDefaults loglinelen=0' /etc/sudoers.d/syssudo
    $cmdpre sed -i '/^Defaults[[:space:]]*!syslog$/s/^/#/g' /etc/sudoers
    $cmdpre sed -i '$aDefaults !syslog' /etc/sudoers.d/syssudo
    $cmdpre sed -i '/^User_Alias[[:space:]]*SYS_WUM[[:space:]]*=/s/^/#/g' /etc/sudoers
    $cmdpre sed -i '$aUser_Alias SYS_WUM = maintain' /etc/sudoers.d/syssudo
    $cmdpre sed -i '/^SYS_WUM[[:space:]]*ALL[[:space:]]*=/s/^/#/g' /etc/sudoers
    $cmdpre sed -i '$aSYS_WUM ALL=(ALL)NOPASSWD: ALL' /etc/sudoers.d/syssudo

  else
  $cmdpre egrep "^Defaults[[:space:]]*logfile[[:space:]]*=[[:space:]]*\/var\/log\/sudo.log$" /etc/sudoers.d/syssudo &>/dev/null
  if [ $? -ne 0 ]
  then
    $cmdpre egrep "^Defaults[[:space:]]*logfile[[:space:]]*=" /etc/sudoers.d/syssudo &>/dev/null
    if [ $? -eq 0 ]
    then
      $cmdpre sed -i '/^Defaults[[:space:]]*logfile[[:space:]]*=/s/^/#/g' /etc/sudoers.d/syssudo
    fi
    $cmdpre sed -i '$aDefaults logfile=\/var\/log\/sudo.log' /etc/sudoers.d/syssudo
  fi

  $cmdpre egrep "^Defaults[[:space:]]*loglinelen[[:space:]]*=[[:space:]]*0$" /etc/sudoers.d/syssudo &>/dev/null
  if [ $? -ne 0 ]
  then
    $cmdpre egrep "^Defaults[[:space:]]*loglinelen[[:space:]]*=" /etc/sudoers.d/syssudo &>/dev/null
    if [ $? -eq 0 ]
    then
      $cmdpre sed -i '/^Defaults[[:space:]]*loglinelen[[:space:]]*=/s/^/#/g' /etc/sudoers.d/syssudo
    fi
    $cmdpre sed -i '$aDefaults loglinelen=0' /etc/sudoers.d/syssudo
  fi

  $cmdpre egrep "^Defaults[[:space:]]*!syslog$" /etc/sudoers.d/syssudo &>/dev/null
  if [ $? -ne 0 ]
  then
    $cmdpre sed -i '$aDefaults !syslog' /etc/sudoers.d/syssudo
  fi

  $cmdpre egrep "^User_Alias[[:space:]]*SYS_WUM[[:space:]]*=[[:space:]]*maintain$" /etc/sudoers.d/syssudo &>/dev/null
  if [ $? -ne 0 ]
  then
    $cmdpre egrep "^User_Alias[[:space:]]*SYS_WUM[[:space:]]*=" /etc/sudoers.d/syssudo &>/dev/null
    if [ $? -eq 0 ]
    then
      $cmdpre sed -i '/^User_Alias[[:space:]]*SYS_WUM[[:space:]]*=/s/^/#/g' /etc/sudoers.d/syssudo
    fi
    $cmdpre sed -i '$aUser_Alias SYS_WUM = maintain' /etc/sudoers.d/syssudo
  fi
 
  $cmdpre egrep "^SYS_WUM[[:space:]]*ALL[[:space:]]*=[[:space:]]*\(ALL\)NOPASSWD:[[:space:]]*ALL$" /etc/sudoers.d/syssudo &>/dev/null
  if [ $? -ne 0 ]
  then
    $cmdpre egrep "^SYS_WUM[[:space:]]*ALL[[:space:]]*=" /etc/sudoers.d/syssudo &>/dev/null
    if [ $? -eq 0 ]
    then
      $cmdpre sed -i '/^SYS_WUM[[:space:]]*ALL[[:space:]]*=/s/^/#/g' /etc/sudoers.d/syssudo
    fi
    $cmdpre sed -i '$aSYS_WUM ALL=(ALL)NOPASSWD: ALL' /etc/sudoers.d/syssudo
  fi
  fi
}


case "$1" in 
  create)
    checkRpm
    createUsers
	sudoConfig
	chPasswd
  ;;
  chpasswd)
    checkRpm
    chPasswd
  ;;
  *)
    echo "Usage: $0 {create|chpasswd} [enracuser]"
	echo -e '\n'
	echo "[$0 create] for create sys user and set password,sudo config"
	echo "[$0 chpasswd] for change exist sys user password"
	echo "[$0 chpasswd|create enracuser] for create/change with grid user"
	exit 2
  ;;
esac