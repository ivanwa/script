#!/bin/bash
#
# Name:renewal_expire_user.sh
# Describe:Check expire user and renewal
# Version:1.0
# Date:2015-3-15
# Author:Ivan Wong
# Email:wangle-it@bestpay.com.cn

me=$(id | awk -F '[=(]' '{print $2}')
if [ $me -eq 0 ]
then
  cmdpre=''
else
  cmdpre='sudo '
fi

#define
threshould_date=12
renewal_length=90

#backup
$cmdpre cp /etc/shadow /etc/shadow_bak_$(date +%Y%m%d%H)
list=$($cmdpre awk -F: '$5 == 99999 || $5 ~ /^$/ {next}{if($2 !~ /^!/) printf ("%s:%d\n",$1,$5 - (int(systime()/86400) - $3))}' /etc/shadow )
for lists in $list;
do
	user=$(echo $lists|cut -d : -f1);
	remain=$(echo $lists|cut -d : -f2);
	if [ $remain -le $threshould_date  ];
	then
		echo "User: ${user}'s password renewal!";
		renewal=$($cmdpre chage -l ${user}|grep Max|awk -F: 'sum=$2+'"$renewal_length"' {print sum}')
		$cmdpre chage -M  +$renewal $user;
	fi
done
