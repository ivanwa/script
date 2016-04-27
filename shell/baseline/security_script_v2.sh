#!/bin/bash
#
# Name:security_script_v2.sh
# Describe:Baselines script
# Version:1.2
# Date:2015-5-17
# Author:Ivan Wong 
# Email:wangle-it@bestpay.com.cn
# Release:
# 2015-5-29 fix bug [histfilesize|ntp|accountlock|rsyslog]
# 2015-6-04 fix bug [accountlock],add [rsyslog role],opt [profile]
# 2015-7-03 add [vsftpd],opt [screenlock],opt [bug fix],support RHEL7
# 2015-7-06	opt [RHEL7 bug fix]
# 2015-8-21	fix bug [nfs screenlock] add [file_permission]
# 2015-8-31 fix bug [pam limit vsftpd] check function no permission
# 2015-9-04 fix [RHEL7 rsyslog no permisson] add [other profile umask 022]
# 2015-9-05 opt [pam]
# 2015-9-06	fix [telnet check|ssh_banner set|pam set]
# 2015-9-09 fix [ntp|profile]
# 2015-9-18 fix [display ntp|rsyslog error]
# 2015-9-21 fix [rhel6.1 pam setting]
# 2015-10-10 add [boot chmod 640 /var/log/boot.log]
# 2015-10-21 fix [fix tallylog 777 permit cause root can't login,fix but tally not work]
# 2015-11-04 opt [rsyslog delete /var/adm/messages]
# 2016-4-20 fix [RHEL7 system-auth bug fix]



#deny_login_conf  userlist
deny_login_userlist=(lp sync halt news uucp operator games gopher smmsp nfsnobody nobody)
#check role file
#log_file=(/var/log/messages /var/log/secure /var/log/cron /var/log/spooler /var/log/boot.log /var/log/authlog /var/adm/messages /var/lib/rsyslog/ /etc/rsyslog.d/)
log_file=(/var/log/messages /var/log/secure /var/log/cron /var/log/spooler /var/log/boot.log /var/log/authlog /var/lib/rsyslog/ /etc/rsyslog.d/)

#who are you
me=$(id | awk -F '[=(]' '{print $2}')
if [ $me -eq 0 ]
then
  cmdpre=''
else
  cmdpre='sudo '
fi

#curry date
now=$(date +%Y%m%d%H%M)

#usage 
function usage(){
echo $0 check
echo $0 set
}
#return code
function dealerr(){
case $2 in
1) echo "The arg of func $1 is wrong.";;
*) echo error code is $2;;
esac
}

#color
function color(){
local colour=$1
local msg=$2
case $colour in
red)    echo -e "\033[31m $msg \033[0m" ;;
green)  echo -e "\033[32m $msg \033[0m" ;;
yellow) echo -e "\033[33m $msg \033[0m" ;;
blue)   echo -e "\033[34m $msg \033[0m" ;;
*)      echo $msg ;;
esac
}


#check dir permission
function dir_permission(){
	local list
    local PART
    local exist=0
    for PART in `sudo grep -v ^# /etc/fstab | awk '($6 != 0) {print $2 }' | sed '/^$/d'`
    do
        list=$(sudo find $PART -xdev -type d \( -perm -0002 -a ! -perm -1000 \) -exec ls -ld {} \; 2>/dev/null)
        if [ "$list" ]
		then
			if [ $exist -eq 0 ]; 
			then 
				color red "The diretory permission check:     [fail]" ; 
				color red "The o+w diretory list is: " ; 
			fi
			color yellow "$list"
			exist=1
		fi
    done
    if [ $exist -eq 0 ]; 
	then 
		color green "The diretory permission check:     [pass]"; 
	else
		color red "The o+w dir permission need modify manually."
	fi
}

#check file permission
function file_permission(){
	local list
    local PART
    local exist=0
    for PART in `sudo grep -v ^# /etc/fstab | awk '($6 != 0) {print $2 }' | sed '/^$/d'`
    do
        list=$(sudo find $PART -xdev -type f \( -perm -0002 -a ! -perm -1000 \) -exec ls -ld {} \; 2>/dev/null)
        if [ "$list" ]
		then
			if [ $exist -eq 0 ]; 
			then 
				color red "The file permission check:         [fail]" ; 
				color yellow "The o+w file list is: " ; 
			fi
			color yellow "$list"
			exist=1
		fi
    done
    if [ $exist -eq 0 ]; 
	then 
		color green "The file permission check:         [pass]"; 
	else
		color red "The o+w file permission need modify manually."
	fi
}

#check not root uid=0 user
function danger_user(){
	local d_user=$(cat /etc/passwd | egrep -v "root" | awk -F: '($3==0) {print $1}')
	if [ -z "$d_user" ]
	then
		color green "The danger_user check:             [pass]"
	else
		color red "The danger_user check:             [fail]"
		color yellow "The not root uid=0 user list is:"
		color yellow $d_user
		color red "Please check and delete danger_user"
	fi
}


#check .netrc file 
function netrc_conf() {
	local list=$(find / -maxdepth 3 -name .netrc 2>/dev/null )
	if [ "$list" ]
	then
		color red "The .netrc file config check:      [fail]" ;
	    color yellow "The .netrc file list is: " ; 
	    color yellow $list
	else
		color green "The .netrc file config check:      [pass]";
    fi
}


#check null passwd
function null_passwd_conf() {
	local list=$($cmdpre awk -F: '( $2 == "" ) { print $1 }' /etc/shadow)
	if [ "$list" ]
	then
		color red "The null_passwd config check:        [fail]" ;
	    color yellow "The null_passwd list is: " ; 
		color yellow $list;
	else
		color green "The null_passwd file check:        [pass]";
	fi
}


#deny userlist user login
function deny_login_conf(){
case $1 in
check)
	deny_set=0
	for user in ${deny_login_userlist[@]}
	do
		usershell=$(awk -F: '$1 == "'$user'" {print $7}' /etc/passwd)
		if [[ -n $usershell && $usershell != '/sbin/nologin' ]]
		then
			deny_set=1
			break 
		fi
	done
	if [ $deny_set -eq 0 ]
	then
		color green "The deny user login config check:  [pass]"
	else
		color red "The deny user login config check:  [fail]"
	fi	
	;;
set)
	deny_login_conf check &>/dev/null
	if [ $deny_set -ne 0 ]
	then
		shell='\/sbin\/nologin'
		for user in ${deny_login_userlist[@]}
		do
			$cmdpre sed -i  "/^\<$user\>/s/\(.*\):[^:]*$/\1:$shell/"  /etc/passwd
		done
	fi
	color green "The deny user login config set:    [ok]"
	deny_login_conf check
	;;
*) dealerr "deny_login_conf" 1 ;;
esac
}


#limit config
function limits_conf(){
case $1 in
check)
	$cmdpre egrep "^\*[[:space:]]*soft[[:space:]]*core[[:space:]]*0" /etc/security/limits.conf &>/dev/null
	limit1=$?
	$cmdpre egrep "^\*[[:space:]]*hard[[:space:]]*core[[:space:]]*0" /etc/security/limits.conf &>/dev/null
	limit2=$?
	$cmdpre egrep '^ulimit[[:space:]]*-S[[:space:]]*-c[[:space:]]*0' /etc/profile &>/dev/null
	limit3=$?
	if [ $limit1 -eq 0 -a $limit2 -eq 0 -a $limit3 -ne 0 ]
	then
		color green "The limit config check:            [pass]"
		backup=0
	else
		color red "The limit config check:            [fail]"
		backup=1
	fi
	;;
set)
    limits_conf check &>/dev/null
	if [ $backup -eq 1  ]
	then
		$cmdpre cp -p /etc/security/limits.conf /etc/security/limits.conf_bak_$now
	fi
    if [ $limit1 -ne 0  ]
    then
		$cmdpre sed -i '$a* soft core 0' /etc/security/limits.conf
    fi
    if [ $limit2 -ne 0  ]
    then
		$cmdpre sed -i '$a* hard core 0' /etc/security/limits.conf
    fi
	if [ $limit3 -ne 0 ]
	then
		$cmdpre cp -p /etc/profile /etc/profile_bak_$now
		$cmdpre sed -i '/ulimit -S -c 0/d' /etc/profile
	fi
	color green "The limit config set:              [ok]"
	limits_conf check
	;;
*) dealerr "limits_conf" 1 ;;
esac
}


#sysctl config
#deny icmp redirects & ip forward
function sysctl_conf(){
case $1 in
check)
	egrep "net.ipv4.conf.all.accept_redirects[[:space:]]*=[[:space:]]*0$" /etc/sysctl.conf &>/dev/null
	redirects=$?
	egrep "net.ipv4.ip_forward[[:space:]]*=[[:space:]]*0$" /etc/sysctl.conf &>/dev/null
	forward=$?
	#source route check
	sourceroute=0
	local list=$(cat /proc/sys/net/ipv4/conf/*/accept_source_route)
    local value
    for value in $list
    do
		if [ $value -eq 1 ]
		then
			sourceroute=1
			break
		fi
    done
	if [ $redirects -eq 0 -a $forward -eq 0 -a $sourceroute -eq 0 ]
	then
		color green "The sysctl config check:           [pass]"
		backup=0
	else
		color red "The sysctl config check:           [fail]"
		backup=1
	fi
	;;
set)
	sysctl_conf check &>/dev/null
	if  [ $backup -eq 1 ]
	then
		$cmdpre cp -p  /etc/sysctl.conf /etc/sysctl.conf_bak_$now
	fi
	if [ $redirects -ne 0 ]
	then
		grep 'net.ipv4.conf.all.accept_redirects' /etc/sysctl.conf &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i '/net.ipv4.conf.all.accept_redirects/s/net.ipv4.conf.all.accept_redirects.*/net.ipv4.conf.all.accept_redirects = 0/g' /etc/sysctl.conf
		else
			$cmdpre sed -i '$anet.ipv4.conf.all.accept_redirects = 0' /etc/sysctl.conf
		fi
	fi
	if [ $forward -ne 0 ]
	then
		grep 'net.ipv4.ip_forward' /etc/sysctl.conf &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i '/net.ipv4.ip_forward/s/net.ipv4.ip_forward.*/net.ipv4.ip_forward = 0/g' /etc/sysctl.conf
		else
			$cmdpre sed -i '$anet.ipv4.ip_forward = 0' /etc/sysctl.conf
		fi		
	fi
	if [ $sourceroute -ne 0 ]
	then		
		local interface
		local list=$(ls /proc/sys/net/ipv4/conf)
		for interface in $list
		do
			$cmdpre echo 0 >/proc/sys/net/ipv4/conf/${interface}/accept_source_route &>/dev/null
			egrep "^net.ipv4.conf.${interface}.accept_source_route" /etc/sysctl.conf &>/dev/null
			if [ $? -eq 0 ]
			then
				sed -i 's/^net.ipv4.conf.'"${interface}"'.accept_source_route.*/net.ipv4.conf.'"${interface}"'.accept_source_route = 0/g' /etc/sysctl.conf
			else
				$cmdpre sed -i '$anet.ipv4.conf.'"$interface"'.accept_source_route = 0' /etc/sysctl.conf
			fi
		done	
	fi
	sysctl -p &>/dev/null
	color green "The sysctl config set:             [ok]"
	sysctl_conf check
	;;
*) dealerr "sysctl_conf" 1 ;;
esac
}


#host config
#更改主机解析地址的顺序
function host_conf(){ 
case $1 in
check)
	egrep "order[[:space:]]*hosts,bind$" /etc/host.conf &>/dev/null
	order=$?
	egrep "multi[[:space:]]*on$" /etc/host.conf &>/dev/null
	multi=$?
	egrep "nospoof[[:space:]]*on$" /etc/host.conf &>/dev/null
	nospoof=$?
	if [ $order -eq 0 -a $multi -eq 0 -a $nospoof -eq 0 ]
	then
		color green "The host config check:             [pass]"
		backup=0
	else
		color red "The host config check:             [fail]"
		backup=1
	fi
	;;
set)
	host_conf check &>/dev/null
	if [ $backup -eq 1 ]
	then
		$cmdpre cp -p /etc/host.conf /etc/host.conf_bak_$now
	fi
	if [ $order -ne 0 ]
	then
		grep "order" /etc/host.conf &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i '/order/s/order .*/order hosts,bind/g' /etc/host.conf
		else
			$cmdpre sed -i '$aorder hosts,bind' /etc/host.conf
		fi
	fi
	if [ $multi -ne 0 ]
	then
		grep "multi" /etc/host.conf &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i '/multi/s/multi .*/multi on/g' /etc/host.conf
		else
			$cmdpre echo '$amulti on' /etc/host.conf
		fi
	fi
	if [ $nospoof -ne 0 ]
	then
		grep "nospoof" /etc/host.conf &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i '/nospoof/s/nospoof .*/nospoof on/g' /etc/host.conf
		else
			$cmdpre sed -i '$anospoof on' /etc/host.conf
		fi
	fi
	color green "The host config set:               [ok]"
	host_conf check
	;;
*) dealerr "host_conf" 1 ;;
esac
}	


#pam config
function pam_conf(){
case $1 in 
check)
	#Password complexity and number of attempts
	egrep "^password[[:space:]]*requisite[[:space:]]*pam_cracklib.so[[:space:]]*try_first_pass[[:space:]]*retry=3[[:space:]]*dcredit=-1[[:space:]]*lcredit=-1[[:space:]]*ucredit=-1[[:space:]]*ocredit=-1[[:space:]]*minlen=8$" /etc/pam.d/system-auth &>/dev/null 
	pam1=$?
	egrep "^password[[:space:]]*sufficient[[:space:]]*pam_unix.so[[:space:]]*sha512[[:space:]]*shadow[[:space:]]*nullok[[:space:]]*try_first_pass[[:space:]]*use_authtok[[:space:]]*remember=5$" /etc/pam.d/system-auth &>/dev/null
	pam2=$?
	$cmdpre  [ -e /etc/security/opasswd ]
	pam3=$?
	#account lock config
	sed -n $(echo $(sed -n '/^auth[[:space:]]*requisite[[:space:]]*pam_succeed_if.so[[:space:]]*uid >= 500 quiet/{=;q}' /etc/pam.d/system-auth)+1|bc)p /etc/pam.d/system-auth|egrep "^auth[[:space:]]*required[[:space:]]*pam_tally2.so[[:space:]]*deny=5[[:space:]]*onerr=fail[[:space:]]*unlock_time=180" &>/dev/null
	#egrep "^auth[[:space:]]*required[[:space:]]*pam_tally2.so[[:space:]]*deny=5[[:space:]]*onerr=fail[[:space:]]*unlock_time=180" /etc/pam.d/system-auth &>/dev/null
	lock1=$?
	
	#rhel6.6-This is right way. 
	#sed -n $(sed -n '/^auth/{=;q}' /etc/pam.d/sshd)p /etc/pam.d/sshd|egrep "^auth[[:space:]]*required[[:space:]]*pam_tally2.so[[:space:]]*deny=5[[:space:]]*onerr=fail[[:space:]]*unlock_time=180" &>/dev/null
	
	#compatible rhel6.1---is bug and wrong way
	sed -n $(echo $(sed -n '/^account/{=;q}' /etc/pam.d/sshd)-1|bc)p /etc/pam.d/sshd|egrep "^auth[[:space:]]*required[[:space:]]*pam_tally2.so[[:space:]]*deny=5[[:space:]]*onerr=fail[[:space:]]*unlock_time=180" &>/dev/null

	lock2=$?
	sed -n $(sed -n '/^account/{=;q}' /etc/pam.d/system-auth)p /etc/pam.d/system-auth|egrep "^account[[:space:]]*required[[:space:]]*pam_tally2.so" &>/dev/null
	lock3=$?
	if [ $pam1 -eq 0 -a $pam2 -eq 0 -a $pam3 -eq 0 -a $lock1 -eq 0 -a $lock2 -eq 0 -a $lock3 -eq 0 ]
	then
		color green "The pam config check:              [pass]"
		backup=0
	else
		color red "The pam config check:              [fail]"
		backup=1
	fi
	;;
set)
	pam_conf check &>/dev/null
	if [ $backup -eq 1 ]
	then
		$cmdpre cp -p /etc/pam.d/system-auth /etc/pam.d/system-auth_bak_$now
		$cmdpre cp -p /etc/pam.d/sshd /etc/pam.d/sshd_bak_$now
	fi
	if [ $pam1 -ne 0 ]
	then
		egrep "^password[[:space:]]*requisite[[:space:]]*pam_cracklib.so" /etc/pam.d/system-auth &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i 's/password    requisite     pam_cracklib.so .*/password    requisite     pam_cracklib.so try_first_pass retry=3 dcredit=-1 lcredit=-1 ucredit=-1 ocredit=-1 minlen=8/g' /etc/pam.d/system-auth
		else
			$cmdpre sed -i `sed -n '/^password/{=;q}' /etc/pam.d/system-auth`'ipassword    requisite     pam_cracklib.so try_first_pass retry=3 dcredit=-1 lcredit=-1 ucredit=-1 ocredit=-1 minlen=8' /etc/pam.d/system-auth
		fi
	fi
	if [ $pam2 -ne 0 ]
	then
		egrep "^password[[:space:]]*sufficient[[:space:]]*pam_unix.so[[:space:]]*sha512[[:space:]]*shadow[[:space:]]*nullok[[:space:]]*try_first_pass[[:space:]]*use_authtok" /etc/pam.d/system-auth &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i 's/password[[:space:]]*sufficient[[:space:]]*pam_unix.so.*/& remember=5/g' /etc/pam.d/system-auth
		else
			$cmdpre sed -i '/password[[:space:]]*sufficient[[:space:]]*pam_unix.so.*/s/^/#/g' /etc/pam.d/system-auth
			$cmdpre sed -i '/password[[:space:]]*requisite[[:space:]]*pam_cracklib.so/apassword    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=5' /etc/pam.d/system-auth
		fi	
	fi
	if [ $pam3 -ne 0 ]
	then
		$cmdpre touch /etc/security/opasswd
		$cmdpre chown root:root /etc/security/opasswd
		$cmdpre chmod 600 /etc/security/opasswd		
	fi
	if [ $lock1 -ne 0 ]
	then
		egrep "^auth[[:space:]]*required[[:space:]]*pam_tally2.so" /etc/pam.d/system-auth &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i '/auth[[:space:]]*required[[:space:]]*pam_tally2.so.*/s/^/#/g' /etc/pam.d/system-auth
			#$cmdpre sed -i `sed -n '/^auth/{=;q}' /etc/pam.d/system-auth`'aauth required pam_tally2.so deny=5 onerr=fail unlock_time=180' /etc/pam.d/system-auth
			$cmdpre sed -i `sed -n '/^auth[[:space:]]*requisite[[:space:]]*pam_succeed_if.so.*/{=;q}' /etc/pam.d/system-auth`'aauth required pam_tally2.so deny=5 onerr=fail unlock_time=180' /etc/pam.d/system-auth
			#$cmdpre sed -i  's/auth[[:space:]]*required[[:space:]]*pam_tally2.so.*/auth required pam_tally2.so deny=5 onerr=fail unlock_time=180/g' /etc/pam.d/system-auth
		else
			#$cmdpre sed -i `sed -n '/^auth/{=;q}' /etc/pam.d/system-auth`'aauth required pam_tally2.so deny=5 onerr=fail unlock_time=180' /etc/pam.d/system-auth
			$cmdpre sed -i `sed -n '/^auth[[:space:]]*requisite[[:space:]]*pam_succeed_if.so.*/{=;q}' /etc/pam.d/system-auth`'aauth required pam_tally2.so deny=5 onerr=fail unlock_time=180' /etc/pam.d/system-auth
		fi
	fi
	if [ $lock2 -ne 0 ]
	then
		#egrep "^auth[[:space:]]*required[[:space:]]*pam_tally2.so" /etc/pam.d/sshd &>/dev/null
		#if [ $? -eq 0 ]
		#then
			$cmdpre sed -i '/^auth[[:space:]]*required[[:space:]]*pam_tally2.so.*/s/^/#/g' /etc/pam.d/sshd
			#rhel6.6-This is right way. 
			#$cmdpre sed -i `sed -n '/^auth/{=;q}' /etc/pam.d/sshd`'iauth required pam_tally2.so deny=5 onerr=fail unlock_time=180' /etc/pam.d/sshd
			
			#compatible rhel6.1---is bug and wrong way
			$cmdpre sed -i `sed -n '/^account/{=;q}' /etc/pam.d/sshd`'iauth required pam_tally2.so deny=5 onerr=fail unlock_time=180' /etc/pam.d/sshd
			#$cmdpre sed  -i 's/auth[[:space:]]*required[[:space:]]*pam_tally2.so.*/auth required pam_tally2.so deny=5 onerr=fail unlock_time=180/g' /etc/pam.d/sshd
		#else
			#$cmdpre sed -i `sed -n '/^auth/{=;q}' /etc/pam.d/sshd`'iauth required pam_tally2.so deny=5 onerr=fail unlock_time=180' /etc/pam.d/sshd
		#fi
	fi
	if [ $lock3 -ne 0 ] 
	then
		$cmdpre sed -i '/^account[[:space:]]required[[:space:]]pam_tally2.so/s/^/#/g' /etc/pam.d/system-auth
		$cmdpre sed -i  `sed -n '/^account/{=;q}' /etc/pam.d/system-auth`'iaccount required pam_tally2.so' /etc/pam.d/system-auth
	fi
	color green "The pam config set:                [ok]"
	pam_conf check
	;;
*) dealerr "pam_conf" 1 ;;
esac
}

#profile config
function profile_conf(){
case $1 in
check)
	#login timeout
	egrep "^export[[:space:]]*TMOUT[[:space:]]*=[[:space:]]*300$" /etc/profile &>/dev/null
	tmout=$?
	#hist command size
	egrep "^export[[:space:]]*HISTSIZE[[:space:]]*=[[:space:]]*5$" /etc/profile &>/dev/null
	histsize=$?
	egrep "^export[[:space:]]*HISTSIZE[[:space:]]*=[[:space:]]*5$" /etc/profile &>/dev/null
	histsize2=$?
	egrep "^export[[:space:]]*HISTFILESIZE[[:space:]]*=[[:space:]]*5$" /etc/profile &>/dev/null
	histfilesize=$?
	#process limit
	#grep ulimit /etc/profile &>/dev/null
	#ulimit=$?
	egrep "umask[[:space:]]*027$" /etc/profile &>/dev/null
	umask=$?
	#set other profile umask 022
	skel=0
	opfs=$($cmdpre find / -type f -maxdepth 3 -name .bash_profile 2>/dev/null)
	for opf in $opfs
	do
		$cmdpre egrep "umask[[:space:]]*022$" $opf &>/dev/null
		if [ $? -ne 0 ]
		then
			skel=1
			break
		fi
	done
	#if [ $tmout -eq 0 -a $histsize -eq 0 -a $histsize2 -eq 0 -a $histfilesize -eq 0 -a $ulimit -ne 0 -a $umask -eq 0 ]
	if [ $tmout -eq 0 -a $histsize -eq 0 -a $histsize2 -eq 0 -a $histfilesize -eq 0 -a $umask -eq 0 -a $skel -eq 0 ]
	then
		color green "The profile config check:          [pass]"
		backup=0
	else
		color red "The profile config check:          [fail]"
		backup=1
	fi
	;;
set)
	profile_conf check &>/dev/null
	if [ $backup -eq 1 ]
	then
		$cmdpre cp -p /etc/profile /etc/profile_bak_$now
	fi
	if [ $tmout -ne 0 ]
	then
		egrep "^export[[:space:]]*TMOUT" /etc/profile &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i 's/^export[[:space:]]*TMOUT.*/export TMOUT=300/g' /etc/profile
		else
			$cmdpre sed -i '$aexport TMOUT=300' /etc/profile
		fi
	fi
	if [ $histsize -ne 0 ]
	then
		egrep "^export[[:space:]]*HISTSIZE" /etc/profile &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i 's/^export[[:space:]]*HISTSIZE.*/HISTSIZE=5/g' /etc/profile
		else
			$cmdpre sed -i '$aexport HISTSIZE=5' /etc/profile
		fi
	fi
	if [ $histsize2 -ne 0 ]
	then
		$cmdpre sed -i 's/^HISTSIZE.*/HISTSIZE=5/g' /etc/profile
	fi
	if [ $histfilesize -ne 0 ]
	then
		egrep "^export[[:space:]]*HISTFILESIZE" /etc/profile &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i 's/^export[[:space:]]*HISTFILESIZE.*/export HISTFILESIZE=5/g' /etc/profile
		else 
			$cmdpre sed -i '$aexport HISTFILESIZE=5' /etc/profile
		fi
	fi
	#if [ $ulimit -eq 0 ]
	#then
	#	$cmdpre sed -i '/ulimit/d' /etc/profile
	#fi
	if [ $umask -ne 0 ]
	then
		grep umask /etc/profile &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i 's/umask.*/umask 027/g' /etc/profile
		else
			$cmdpre sed -i '$aumask 027' /etc/profile
		fi
	fi
	if [ $skel -ne 0 ]
	then
		for opf in $opfs
		do
			$cmdpre grep umask $opf &>/dev/null
			if [ $? -eq 0 ]
			then
				$cmdpre sed -i 's/umask.*/umask 022/g' $opf
			else
				$cmdpre sed -i '$aumask 022' $opf
			fi
		done
	fi
	#$cmdpre source /etc/profile &>/dev/null
	color green "The profile config set:            [ok]"
	profile_conf check
	;;
*) dealerr "profile_conf" 1 ;;	
esac
}


#rsyslong config
function rsyslog_conf(){
case $1 in
check)
	egrep "^auth.info[[:space:]]*/var/log/authlog$" /etc/rsyslog.conf  &>/dev/null
	auth1=$?
	[ -e /var/log/authlog ]
	auth2=$?
	egrep "^authpriv.\*[[:space:]]*/var/log/secure$" /etc/rsyslog.conf &>/dev/null
	secure1=$?
	[ -e /var/log/secure ]
	secure2=$?
	egrep "^cron.\*[[:space:]]*/var/log/cron$" /etc/rsyslog.conf &>/dev/null
	cron1=$?
	[ -e /var/log/cron ]
	cron2=$?
	#egrep "^\*.err;kern.debug;daemon.notice[[:space:]]*/var/adm/messages" /etc/rsyslog.conf &>/dev/null
	#adm1=$?
	#$cmdpre [ -e /var/adm/messages ]
	#adm2=$?
	egrep "^\*.\*[[:space:]]*@132.97.127.69:514" /etc/rsyslog.conf &>/dev/null
	log=$?
	role=0
	for logs in ${log_file[@]}
	do
		if [ -e $logs ]
		then
			if [ -d $logs ]
			then
				#cd $logs
				$cmdpre ls -l $logs |sed 1,3d|grep -v "[r-][w-]-[r-]-----" &>/dev/null
				if [ $? -eq 0  ]
				then
					role=1
					break
				fi
			else
				$cmdpre ls -l $logs |grep -v "[r-][w-]-[r-]-----" &>/dev/null
				if [ $? -eq 0  ]
				then
					role=1
					break
				fi
			fi
		fi
	done
	#$cmdpre sed -n 1p /etc/logrotate.d/syslog |egrep "^/var/adm/messages$" &>/dev/null
	#rotate=$?
	#if [ $auth1 -eq 0 -a $auth2 -eq 0 -a $secure1 -eq 0 -a $secure2 -eq 0 -a $cron1 -eq 0 -a $cron2 -eq 0 -a $adm1 -eq 0 -a $adm2 -eq 0 -a $log -eq 0 -a $role -eq 0 -a $rotate -eq 0 ]
	if [ $auth1 -eq 0 -a $auth2 -eq 0 -a $secure1 -eq 0 -a $secure2 -eq 0 -a $cron1 -eq 0 -a $cron2 -eq 0 -a $log -eq 0 -a $role -eq 0 ]
	then
		color green "The rsyslog config check:          [pass]"
		backup=0
	else
		color red "The rsyslog config check:          [fail]"
		backup=1
		fi
	;;
set)
	rsyslog_conf check &>/dev/null
	if [ $backup -eq 1 ]
	then
		$cmdpre cp -p /etc/rsyslog.conf /etc/rsyslog.conf_bak_$now
	fi
	if [ $auth2 -ne 0 ]
	then
		$cmdpre touch /var/log/authlog
		$cmdpre chmod 640 /var/log/authlog
	fi
	if [ $auth1 -ne 0 ]
	then
		grep "^auth.info" /etc/rsyslog.conf &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i 's/^auth.info.*/auth.info  \/var\/log\/authlog/g' /etc/rsyslog.conf
		else
			$cmdpre sed -i '$aauth.info  \/var\/log\/authlog' /etc/rsyslog.conf
		fi
	fi
	if [ $secure2 -ne 0 ]
	then
		$cmdpre touch /var/log/secure
		$cmdpre chmod 640 /var/log/secure
	fi
	if [ $secure1 -ne 0 ]
	then
		grep "^authpriv.\*" /etc/rsyslog.conf &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i 's/^authpriv.*/authpriv.*  \/var\/log\/secure/g' /etc/rsyslog.conf
		else
			$cmdpre sed -i '$aauthpriv.*  \/var\/log\/secure' /etc/rsyslog.conf
		fi
	fi
	if [ $cron2 -ne 0 ]
	then
		$cmdpre touch /var/log/cron
		$cmdpre chmod 640 /var/log/cron
	fi
	if [ $cron1 -ne 0 ]
	then
		grep "^cron.\*" /etc/rsyslog.conf &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i 's/^cron.*/cron.*  \/var\/log\/cron/g' /etc/rsyslog.conf
		else
			$cmdpre sed -i '$acron.* \/var\/log\/cron' /etc/rsyslog.conf
		fi
	fi
	#if [ $adm1 -ne 0 ]
	#then
	#	egrep "^\*.err;kern.debug;daemon.notice" /etc/rsyslog.conf &>/dev/null
	#	if [ $? -eq 0 ]
	#	then
	#		$cmdpre sed -i 's/^*.err;kern.debug;daemon.notice.*/*.err;kern.debug;daemon.notice  \/var\/adm\/messages/g' /etc/rsyslog.conf &>/dev/null
	#	else
	#		$cmdpre sed -i '$a*.err;kern.debug;daemon.notice \/var\/adm\/messages' /etc/rsyslog.conf
	#	fi
	#fi
	#if [ $adm2 -ne 0 ]
	#then
	#	$cmdpre mkdir /var/adm  &>/dev/null
	#	$cmdpre touch /var/adm/messages &>/dev/null
	#	$cmdpre chmod 640 /var/adm/messages
	#fi
	if [ $log -ne 0 ]
	then
		$cmdpre sed -i '$a*.* @132.97.127.69:514' /etc/rsyslog.conf &>/dev/null
	fi
	if [ $role -ne 0 ]
	then
		$cmdpre egrep "^\chmod[[:space:]]*640[[:space:]]*/var/log/boot.log" /etc/rc.local &>/dev/null
		if [ $? -ne 0 ]
		then
			$cmdpre sed -i '$achmod 640 /var/log/boot.log' /etc/rc.local &>/dev/null
		fi
		for logs in ${log_file[@]}
		do
			if [ -d $logs ]
			then
				#cd $logs
				$cmdpre ls -l $logs |sed 1,3d|grep -v "[r-][w-]-[r-]-----" &>/dev/null
				if [ $? -eq 0  ]
				then
					$cmdpre chmod 640 ${logs}/* &>/dev/null
				fi
			else
				if [ -e $logs ]
				then
					$cmdpre chmod -R 640 $logs &>/dev/null
				fi
			fi
		done
	fi
	#if [ $rotate -ne 0 ]
	#then
	#	$cmdpre egrep "^/var/adm/messages$" /etc/logrotate.d/syslog &>/dev/null
	#	if [ $? -eq 0 ]
	#	then
	#		$cmdpre sed -i '/\/var\/adm\/messages/s/^/#/g' /etc/logrotate.d/syslog &>/dev/null
	#	fi
	#	$cmdpre sed -i '1 i\/var\/adm\/messages'  /etc/logrotate.d/syslog &>/dev/null
	#fi
	$cmdpre /etc/init.d/rsyslog restart &>/dev/null
	color green "The rsyslog config set:            [ok]"
	rsyslog_conf check
	;;
*) dealerr "rsyslog_conf" 1 ;;	
esac
}


#nfs config
function nfs_conf(){
case $1 in
check)
	if [ -f /etc/init.d/nfs ]
	then
		$cmdpre service nfs status | grep running &>/dev/null
		nfs_run=$?
	else
		color yellow "The NFS service not installed."
		nfs_run=1
	fi
	if [ $nfs_run -eq 0 ]
	then
		color yellow "The NFS service started, please check /etc/hosts.allow and /etc/hosts.deny" 
		color red "The nfs config check:              [fail]"
	else
		color green "The nfs config check:              [pass]"
	fi
	;;
set)
	nfs_conf check &>/dev/null
	if [ $nfs_run -ne 0 ]
	then
		$cmdpre chkconfig nfs off &>/dev/null
		$cmdpre chkconfig nfslock off &>/dev/null
		$cmdpre service nfslock stop &>/dev/null
	else
		color yellow "The NFS service started, please modify manually"
	fi
	color green "The nfs config set:                [ok]"
	nfs_conf check
	;;
*) dealerr "nfs_conf" 1
esac
}


#检查是否设置屏幕锁定
function screenlock_conf(){
case $1 in
check)
    if [ -f /usr/bin/gconftool-2 ]
    then
		idle_activation_enabled=$($cmdpre gconftool-2 -g /apps/gnome-screensaver/idle_activation_enabled 2>/dev/null)
		lock_enabled=$($cmdpre gconftool-2 -g /apps/gnome-screensaver/lock_enabled 2>/dev/null)
		mode=$($cmdpre gconftool-2 -g /apps/gnome-screensaver/mode 2>/dev/null)
		idle_delay=$($cmdpre gconftool-2 -g /apps/gnome-screensaver/idle_delay 2>/dev/null)
		if [[ $idle_activation_enabled == "true" && $lock_enabled == "true" && $mode == "blank-only" && $idle_delay == "15" ]]
		then
			screen_set=0
			color  green "The screenlock config check:       [pass]"
		else
			screen_set=1
			color red "The screenlock config check:       [fail]"
		fi
    else
		screen_set=0
		color yellow "The gconftool-2 or desktop not installed."
		color green "The screenlock config check:       [pass]" 
    fi
    ;;
set)
	screenlock_conf check &>/dev/null
	if [ $screen_set -eq 1 ]
	then
		if [ ! -e /root/.config ]
		then
			$cmdpre mkdir /root/.config &>/dev/null
		fi
		$cmdpre gconftool-2 -t bool -s /apps/gnome-screensaver/idle_activation_enabled 'true'
		$cmdpre gconftool-2 -t bool -s /apps/gnome-screensaver/lock_enabled 'true'
		$cmdpre gconftool-2 -t string -s /apps/gnome-screensaver/mode 'blank-only'
		$cmdpre gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults -t int -s /apps/gnome-screensaver/idle_delay 15
	fi
	color green "The screenlock config set:         [ok]" 
	screenlock_conf check
	;;
*) dealerr "screenlock_conf" 1
esac
}


#指定组拥有su权限
function su_conf(){
case $1 in
check)
	egrep "^auth[[:space:]]*required[[:space:]]*pam_wheel.so[[:space:]]*group=wheel[[:space:]]*use_uid[[:space:]]*root_only" /etc/pam.d/su &>/dev/null
	if [ $? -eq 0 ]
	then
		color green "The su config check:               [pass]" 
		backup=0
	else
		color red "The su config check:               [fail]" 
		backup=1
	fi
     ;;
set)
	su_conf check &>/dev/null
	
	if [ $backup -eq 1 ]
	then
		$cmdpre cp -p /etc/pam.d/su /etc/pam.d/su_bak_$now
		$cmdpre sed -i '/pam_rootok/aauth required pam_wheel.so group=wheel use_uid root_only' /etc/pam.d/su
	fi
	color green "The su config set:                 [ok]"
	su_conf check
   ;;
*) dealerr "su_conf" 1
esac
}


#rm/ls alias
function alias_conf(){
case $1 in 
check)
	$cmdpre egrep "alias[[:space:]]*ls='ls[[:space:]]*-aol'" /root/.bashrc &>/dev/null
	ls_alias=$?
	$cmdpre egrep "alias[[:space:]]*rm='rm[[:space:]]*-i'" /root/.bashrc &>/dev/null
	rm_alias=$?
	if [ $ls_alias -eq 0 -a $rm_alias -eq 0 ]
	then
		color green "The alias config check:            [pass]"
		backup=0
	else
		color red "The alias config check:            [fail]"
		backup=1
	fi
	;;
set)
	alias_conf check &>/dev/null
	if [ $backup -eq 1 ]
	then
		$cmdpre cp -p /root/.bashrc /root/.bashrc_bak_$now
	fi
	if [ $ls_alias -ne 0 ]
	then
		egrep "alias[[:space:]]*ls" /root/.bashrc &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i 's/alias[[:space:]]*ls.*/alias ls='"'ls -aol'"'/g' /root/.bashrc
		else
			$cmdpre sed -i '$aalias ls='"'ls -aol'"'' /root/.bashrc
		fi		
	fi
	if [ $rm_alias -ne 0 ]
	then
		egrep "alias[[:space:]]*rm" /root/.bashrc &>/dev/null
		if [ $? -eq 0 ]
		then
			$cmdpre sed -i 's/alias[[:space:]]*rm.*/alias rm='"'rm -i'"'/g' /root/.bashrc
		else
			$cmdpre sed -i '$aalias rm='"'rm -i'"''  /root/.bashrc
		fi
	fi
	color green "The alias config set:              [ok]"
	alias_conf check
	;;
*) dealerr "alias_conf" 1
esac
}

#account len and term config
function password_conf(){
case $1 in
check)
	egrep "^PASS_MAX_DAYS[[:space:]]*90$" /etc/login.defs &>/dev/null
	p_max=$?
	egrep "^PASS_MIN_DAYS[[:space:]]*10$" /etc/login.defs &>/dev/null
	p_min=$?
	egrep "^PASS_WARN_AGE[[:space:]]*7$" /etc/login.defs &>/dev/null
	p_warn=$?
	egrep "^PASS_MIN_LEN[[:space:]]*8$" /etc/login.defs &>/dev/null
	p_len=$?
	if [ $p_max -eq 0 -a $p_min -eq 0 -a $p_warn -eq 0 -a $p_len -eq 0 ]
	then
		color green "The password config check:         [pass]"
		backup=0
	else
		color red "The password config check:         [fail]"
		backup=1
	fi
	;;
set)
	password_conf check &>/dev/null
	if [ $backup -eq 1 ]
	then
		$cmdpre cp -p /etc/login.defs /etc/login.defs_bak_$now
		if [ $p_max -ne 0 ]
		then
			egrep "^PASS_MAX_DAYS" /etc/login.defs &>/dev/null
			if [ $? -eq 0 ]
			then
				$cmdpre sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
			else
				$cmdpre sed -i '$aPASS_MAX_DAYS 90' /etc/login.defs
			fi
		fi
		if [ $p_min -ne 0 ]
		then
			egrep "^PASS_MIN_DAYS" /etc/login.defs &>/dev/null
			if [ $? -eq 0 ]
			then
				$cmdpre sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 10/' /etc/login.defs
			else
				$cmdpre sed -i '$aPASS_MIN_DAYS	10' /etc/login.defs
			fi
		fi
		if [ $p_warn -ne 0 ]
		then
			egrep "^PASS_WARN_AGE" /etc/login.defs &>/dev/null
			if [ $? -eq 0 ]
			then
				$cmdpre sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs
			else
				$cmdpre sed -i '$aPASS_WARN_AGE	7' /etc/login.defs
			fi
		fi
		if [ $p_len -ne 0 ]
		then
			egrep "^PASS_MIN_LEN" /etc/login.defs &>/dev/null
			if [ $? -eq 0 ]
			then
				$cmdpre sed -i 's/^PASS_MIN_LEN.*/PASS_MIN_LEN 8/' /etc/login.defs
			else
				$cmdpre sed -i '$aPASS_MIN_LEN 8' /etc/login.defs
			fi
		fi
	fi
	color green "The password config set:           [ok]"
	password_conf check
	;;
*) dealerr "password_conf" 1
esac
}


#main file permission config
function permission_conf(){
case $1 in
check)
	local permission
	permission=$(stat /etc/passwd | grep Uid | awk -F '[(/]' '{print $2}')
	if [ $permission != 0644 ]
    then
		passwd_access=1
	else
		passwd_access=0
	fi
	permission=$(stat /etc/group  | grep Uid | awk -F '[(/]' '{print $2}')
	if [ $permission != 0644 ]
    then
		group_access=1
	else
		group_access=0
	fi
	permission=$(stat /etc/services  | grep Uid | awk -F '[(/]' '{print $2}')
	if [ $permission != 0644 ]
    then
		services_access=1
	else
		services_access=0
	fi
	permission=$(stat /etc/shadow  | grep Uid | awk -F '[(/]' '{print $2}')
	if [ $permission != 0000 ]
    then
		shadow_access=1
	else
		shadow_access=0
	fi
	if [ -f /etc/xinetd.conf ]
    then
		permission=$(stat /etc/xinetd.conf | grep Uid | awk -F '[(/]' '{print $2}')
		if [ $permission != 0600 ]
		then
			xinetd_access=1
		else
			xinetd_access=0
       fi
	else
		xinetd_access=0
    fi
	permission=$(stat /etc/security  | grep Uid | awk -F '[(/]' '{print $2}')
	if [ $permission != 0600 ]
    then
		security_access=1
	else
		security_access=0
	fi
	if [ $passwd_access -eq 0 -a $group_access -eq 0 -a $services_access -eq 0 -a $shadow_access -eq 0 -a $xinetd_access -eq 0 -a $security_access -eq 0 ]
	then
		color green "The permission config check:       [pass]"
		permission_set=0
	else
		color red "The permission config check:       [fail]"
		permission_set=1
	fi
	;;
set)
	permission_conf check &>/dev/null
	if [ $permission_set -ne 0 ]
	then
		if [ $passwd_access -eq 1 ]
		then
			$cmdpre chmod 644 /etc/passwd
		fi
		if [ $group_access -eq 1 ]
		then
			$cmdpre chmod 644 /etc/group
		fi
		if [ $services_access -eq 1 ]
		then
			$cmdpre chmod 644 /etc/services
		fi
		if [ $shadow_access -eq 1 ]
		then
			$cmdpre chmod 000 /etc/shadow
		fi
		if [ $xinetd_access -eq 1 ]
		then
			$cmdpre chmod 600 /etc/xinetd.conf
		fi
		if [ $security_access -eq 1 ]
		then
			$cmdpre chmod 600 /etc/security
		fi
	fi
	color green "The permission config set:         [ok]"
	permission_conf check
	;;
*) dealerr "password_conf" 1
esac
}


#ssh banner config
function sshbanner_conf(){
case $1 in
check)
	$cmdpre egrep "^[[:space:]]*Banner[[:space:]]*/etc/motd" /etc/ssh/sshd_config &>/dev/null
    if [ $? -eq 0 ]
    then 		
		color green "The ssh banner config check:       [pass]" 
		backup=0
    else
		color red "The ssh banner config check:       [fail]"
		backup=1
	fi
	;;
set)
	sshbanner_conf check &>/dev/null
	if [ $backup -eq 1 ]
	then
		$cmdpre cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config_bak_$now
		[ -e /etc/motd ] || $cmdpre touch /etc/motd
		$cmdpre chmod 666 /etc/motd && echo " Authorized only. All activity will be monitored and reported " > /etc/motd && $cmdpre chmod 644 /etc/motd
		$cmdpre egrep "^Banner" /etc/ssh/sshd_config &>/dev/null
		if [ $? -eq 0 ] ; then
			$cmdpre sed -i '/^Banner.*/s/Banner.*/Banner \/etc\/motd/g' /etc/ssh/sshd_config
		else
			$cmdpre sed -i '$aBanner \/etc\/motd' /etc/ssh/sshd_config
		fi
		$cmdpre service sshd reload &>/dev/null
	fi
	color green "The ssh banner config set:         [ok]" 
	sshbanner_conf check
	;;
*) dealerr "sshbanner_conf" 1
esac
}


#telnet config
function telnet_conf(){
case $1 in
check)
	if [ ! -e /etc/xinetd.d/telnet ]
	then
		color yellow "The telnet service not installed"
		color green "The tenlet config check:           [pass]"
		backup=0
	else
		egrep "^[[:space:]]*disable[[:space:]]*=[[:space:]]*yes"  /etc/xinetd.d/telnet &>/dev/null
		telnet_conf=$?
		$cmdpre service xinetd status |grep running &>/dev/null
		telnet_status=$?
		if [ $telnet_conf -ne 0 -a $telnet_status -eq 0 ]
		then
			color red "The tenlet config check:           [fail]"
			backup=1
		else
			color green "The tenlet config check:           [pass]"
			backup=0
		fi
	fi
	;;
set)
	telnet_conf check &>/dev/null
	if [ $backup -eq 1 ]
	then
		if [ $telnet_conf -eq 0 ]
		then
			$cmdpre cp -p /etc/xinetd.d/telnet /etc/xinetd.d/telnet_bak_$now
			$cmdpre sed -i 's/[[:space:]]*disable.*/        disable         = yes/g' /etc/xinetd.d/telnet
		fi
		$cmdpre service xinetd reload &>/dev/null
	fi
	color green "The tenlet config set:             [ok]"
	telnet_conf check
	;;
*) dealerr "telnet_conf" 1
esac	
}



#ntp config
function ntp_conf(){
case $1 in
check)
	if [ ! -f /etc/ntp.conf ]
	then
		color yellow "The ntp service not installed"
		color green "The ntp config check:  [pass]"
		backup=0
	else
		egrep '^[[:space:]]*disable[[:space:]]*monitor' /etc/ntp.conf &>/dev/null
		ntp1=$?
		egrep -v '^server[[:space:]]*132.97.126.193[[:space:]]*prefer$' /etc/ntp.conf|grep '^server' &>/dev/null
		ntp2=$?
		egrep '^server[[:space:]]*132.97.126.193[[:space:]]*prefer$' /etc/ntp.conf &>/dev/null
		ntp3=$?
		if [ $ntp1 -eq 0 -a $ntp2 -ne 0 -a $ntp3 -eq 0 ]
		then
			color green "The ntp config check:              [pass]"
			backup=0
		else
			color red "The ntp config check:              [fail]"
			backup=1
		fi
	fi
	;;
set)
	ntp_conf check &>/dev/null
	if [ $backup -eq 1 ]
	then
		$cmdpre cp -p /etc/ntp.conf /etc/ntp.conf_bak_$now
		if [ $ntp1 -ne 0 ]
		then
			$cmdpre sed -i '$adisable monitor' /etc/ntp.conf
		fi
		if [ $ntp2 -eq 0 ]
		then
			for match in $(egrep -v '^server[[:space:]]*132.97.126.193[[:space:]]*prefer$' /etc/ntp.conf|grep '^server'); 
			do
				sed -i '/'^"$match"'/s/^/#/g' /etc/ntp.conf
			done
		fi
		if [ $ntp3 -ne 0 ]
		then
			egrep '^server[[:space:]]*132.97.126.193' /etc/ntp.conf &>/dev/null
			#$cmdpre sed -i '/^server.*/s/^/#/g' /etc/ntp.conf
			if [ $? -eq 0 ]
			then
				$cmdpre sed -i 's/^server[[:space:]]*132.97.126.193.*/server 132.97.126.193 prefer/g' /etc/ntp.conf
			else
				$cmdpre sed -i '$aserver 132.97.126.193 prefer' /etc/ntp.conf
			fi
		fi
		$cmdpre service ntpd restart &>/dev/null
		$cmdpre chkconfig ntpd on &>/dev/null
	fi
	color green "The ntp config set:                [ok]"
	ntp_conf check
	;;
*) dealerr "ntp_conf" 1
esac	
}


#disable ctrl+alt+delete
function key_com_conf(){
case $1 in
check)
	egrep "^exec[[:space:]]*/sbin/shutdown[[:space:]]*-r now[[:space:]]*" /etc/init/control-alt-delete.conf &>/dev/null
	if [ $? -eq 0 ] 
	then
		color red "The key_com config check:          [fail]"
		backup=1
	else
		color green "The key_com config check:          [pass]"
		backup=0
	fi
	;;
set)
	key_com_conf check &>/dev/null
	if [ $backup -eq 1 ]
	then
		$cmdpre cp -p /etc/init/control-alt-delete.conf /etc/init/control-alt-delete.conf_bak_$now
		$cmdpre sed -i  '/^exec[[:space:]]*\/sbin\/shutdown[[:space:]]*-r[[:space:]]*now/s/^/#/g' /etc/init/control-alt-delete.conf
	fi
	color green "The key_com config set:            [ok]"
	key_com_conf check
	;;
*) dealerr "key_com_conf" 1
esac
}

#vsftpd config
function vsftpd_conf(){
case $1 in
check)
	if [ ! -e /etc/vsftpd/vsftpd.conf ]
	then
		color yellow "The vsftpd service not installed"
		color green "The vsftpd config check:           [pass]"
		backup=0
	else
		$cmdpre egrep "ftpd_banner[[:space:]]*=[[:space:]]*\" Authorized users only. All activity may be monitored and reported.\"" /etc/vsftpd/vsftpd.conf  &>/dev/null
		ftpd_banner=$?
		$cmdpre egrep "ls_recurse_enable[[:space:]]*=[[:space:]]*YES" /etc/vsftpd/vsftpd.conf  &>/dev/null
		ls_recurse=$?
		$cmdpre egrep "local_umask[[:space:]]*=[[:space:]]*022" /etc/vsftpd/vsftpd.conf  &>/dev/null
		local_umask=$?
		$cmdpre egrep "anon_umask[[:space:]]*=[[:space:]]*022" /etc/vsftpd/vsftpd.conf  &>/dev/null
        anon_umask=$?
		$cmdpre egrep "chroot_list_enable[[:space:]]*=[[:space:]]*YES" /etc/vsftpd/vsftpd.conf  &>/dev/null
		chroot_list_enable=$?
		$cmdpre egrep "chroot_local_user[[:space:]]*=[[:space:]]*NO" /etc/vsftpd/vsftpd.conf  &>/dev/null
		chroot_local_user=$?
		$cmdpre egrep "chroot_list_file[[:space:]]*=[[:space:]]*/etc/vsftpd/chroot_list" /etc/vsftpd/vsftpd.conf  &>/dev/null
		chroot_list_file=$?
		[ -s /etc/vsftpd/chroot_list ]
		chroot_list=$?
		if [ $ftpd_banner -eq 0 -a $ls_recurse -eq 0 -a $local_umask -eq 0 -a $anon_umask -eq 0 -a $chroot_list_enable -eq 0 -a $chroot_local_user -eq 0 -a $chroot_list_file -eq 0 -a $chroot_list -eq 0 ]
		then
			color green "The vsftpd config check:           [pass]"
			backup=0
		else
			color red "The vsftpd config check:           [fail]"
			backup=1
		fi
		
	fi
	;;
set)
	vsftpd_conf check  &>/dev/null
	if [ $backup -eq 1 ]
	then
		if [ $ftpd_banner -ne 0 ]
		then
			grep "^ftpd_banner[[:space:]]*=" /etc/vsftpd/vsftpd.conf  &>/dev/null
			if [ $? -eq 0 ]
			then
				$cmdpre sed -i 's/^ftpd_banner[[:space:]]*=.*/ftpd_banner=" Authorized users only. All activity may be monitored and reported."/g' /etc/vsftpd/vsftpd.conf
			else
				$cmdpre sed -i '$aftpd_banner=" Authorized users only. All activity may be monitored and reported."' /etc/vsftpd/vsftpd.conf
			fi
		fi
		if [ $ls_recurse -ne 0 ]
		then
			grep "^ls_recurse_enable[[:space:]]*=" /etc/vsftpd/vsftpd.conf  &>/dev/null
			if [ $? -eq 0 ]
			then
				$cmdpre sed -i 's/^ls_recurse_enable[[:space:]]*=.*/ls_recurse_enable=YES/g' /etc/vsftpd/vsftpd.conf  &>/dev/null
			else
				$cmdpre sed -i '$als_recurse_enable=YES' /etc/vsftpd/vsftpd.conf  &>/dev/null
			fi
		fi
		if [ $local_umask -ne 0 ]
		then
			grep "^local_umask[[:space:]]*=" /etc/vsftpd/vsftpd.conf  &>/dev/null
			if [ $? -eq 0 ]
			then
				$cmdpre sed -i 's/^local_umask[[:space:]]*=.*/local_umask=022/g' /etc/vsftpd/vsftpd.conf  &>/dev/null
			else
				$cmdpre sed -i '$alocal_umask=022' /etc/vsftpd/vsftpd.conf  &>/dev/null
			fi
		fi
		if [ $anon_umask -ne 0 ]
		then
			grep "^anon_umask[[:space:]]*=" /etc/vsftpd/vsftpd.conf  &>/dev/null
			if [ $? -eq 0 ]
			then
				$cmdpre sed -i 's/^anon_umask[[:space:]]*=.*/anon_umask=022/g' /etc/vsftpd/vsftpd.conf  &>/dev/null
			else
				$cmdpre sed -i '$aanon_umask=022' /etc/vsftpd/vsftpd.conf  &>/dev/null
			fi
		fi
		if [ $chroot_list_enable -ne 0 ]
		then
			grep "^chroot_list_enable[[:space:]]*=" /etc/vsftpd/vsftpd.conf  &>/dev/null
			if [ $? -eq 0 ]
			then
				$cmdpre sed -i 's/^chroot_list_enable[[:space:]]*=.*/chroot_list_enable=YES/g' /etc/vsftpd/vsftpd.conf  &>/dev/null
			else
				$cmdpre sed -i '$achroot_list_enable=YES' /etc/vsftpd/vsftpd.conf  &>/dev/null
			fi
		fi
		if [ $chroot_local_user -ne 0 ]
		then
			grep "^chroot_local_user[[:space:]]*=" /etc/vsftpd/vsftpd.conf  &>/dev/null
			if [ $? -eq 0 ]
			then
				$cmdpre sed -i 's/^chroot_local_user[[:space:]]*=.*/chroot_local_user=NO/g' /etc/vsftpd/vsftpd.conf  &>/dev/null
			else
				$cmdpre sed -i '$achroot_local_user=NO' /etc/vsftpd/vsftpd.conf  &>/dev/null
			fi
		fi
		if [ $chroot_list_file -ne 0 ]
		then
			grep "^chroot_list_file[[:space:]]*=" /etc/vsftpd/vsftpd.conf  &>/dev/null
			if [ $? -eq 0 ]
			then
				$cmdpre sed -i 's/^chroot_list_file[[:space:]]*=.*/chroot_list_file=/etc/vsftpd/chroot_list/g' /etc/vsftpd/vsftpd.conf  &>/dev/null
			else
				$cmdpre sed -i '$achroot_list_file=/etc/vsftpd/chroot_list' /etc/vsftpd/vsftpd.conf  &>/dev/null
			fi
		fi
		if [ $chroot_list -ne 0 ]
		then
			if [ -e /etc/vsftpd/chroot_list ]
			then
				$cmdpre chmod 666 /etc/vsftpd/chroot_list &>/dev/null
				$cmdpre echo 'root' > /etc/vsftpd/chroot_list
				$cmdpre chmod 600 /etc/vsftpd/chroot_list &>/dev/null
			else
				$cmdpre touch /etc/vsftpd/chroot_list &>/dev/null
				$cmdpre chmod 666 /etc/vsftpd/chroot_list &>/dev/null
				$cmdpre echo 'root' > /etc/vsftpd/chroot_list
				$cmdpre chmod 600 /etc/vsftpd/chroot_list &>/dev/null
			fi
		fi
		ps -ef|grep vsftpd|grep -v grep &>/dev/null
		if [ $? -eq 0 ]
		then
		$cmdpre service vsftpd restart   &>/dev/null
		fi
	fi
	;;
*) dealerr "vsftpd_conf" 1
esac
}

#glibc bash openssl openssh bug check
function bug_conf(){
case $1 in
check)
	rpm -q glibc --changelog |grep CVE-2015-0235 &>/dev/null
	glibc_fix=$?
	rpm -q bash --changelog |grep CVE-2014-7169 &>/dev/null
	bash_fix=$?
	rpm -q openssl --changelog |grep CVE-2014-0160 &>/dev/null
	openssl_fix=$?
	ver=$(rpm -qi openssh|grep Version|awk -F: '{print $2}'|awk  '{print $1}'|cut -c1-3)
	openssl_ver=$(expr $ver \>= 6.6)
	if [ $openssl_ver -eq 0 ]
	then
		rpm -q openssh --changelog |grep CVE-2014-2532 &>/dev/null
		openssh_fix=$?
	else
		openssh_fix=0
	fi
	if [ $glibc_fix -eq 0 -a $bash_fix -eq 0 -a $openssl_fix -eq 0 -a $openssh_fix -eq 0 ]
	then
		color green "The bug config check:              [pass]"
		bug_set=0
	else
		color red "The bug config check:              [fail]"
		color yellow "Please check yum config,then run the command manual"
		color yellow "yum install -y  bash openssl openssh glibc glibc.i686"
		bug_set=1
	fi
	;;
set)
	bug_conf check &>/dev/null
	if [ $bug_set -eq 1 ]
	then
		yum update -y  bash openssl openssh glibc glibc.i686  &>/dev/null
		if [ $? -eq 0 ]
		then
			color green "The bug config set:                [ok]"
			bug_conf check
		else
			color red "The bug config set:                [fail]"
			color yellow "Please check yum config,then run the command manual"
			color yellow "yum install -y  bash openssl openssh glibc glibc.i686"		
		fi
	fi
	;;
*) dealerr "bug_conf" 1
esac
}

function docheck(){
	dir_permission
	file_permission
	danger_user
	netrc_conf
	null_passwd_conf
	deny_login_conf    check
	limits_conf        check
	sysctl_conf        check
	host_conf          check
	pam_conf           check
	profile_conf       check
	rsyslog_conf       check
	nfs_conf           check
	screenlock_conf    check
	su_conf            check
	alias_conf         check
	password_conf      check
	permission_conf    check
	sshbanner_conf     check
	telnet_conf        check
	ntp_conf           check
	key_com_conf       check
	vsftpd_conf        check
	bug_conf           check
}

function doset(){
	dir_permission
	file_permission
	danger_user
	netrc_conf
	null_passwd_conf
	deny_login_conf    set
	limits_conf        set
	sysctl_conf        set
	host_conf          set
	pam_conf           set
	profile_conf       set
	rsyslog_conf       set
	nfs_conf           set 
	screenlock_conf    set
	su_conf            set
	alias_conf         set
	password_conf      set
	permission_conf    set
	sshbanner_conf     set
	telnet_conf        set
	ntp_conf           set
	key_com_conf       set
	vsftpd_conf        set
	bug_conf           set
}

#main
case $1 in
check) 
	docheck 
	;;
set)   
	doset 
	color yellow "All complete,please reboot the server!"
	;;
*)     
	usage 
	;;
esac
exit 0
