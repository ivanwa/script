#!/bin/bash
#
# Name:yum-init.sh
# Describe:Yum repo config
# Version:1.0
# Date:2015-8-17
# Author:Ivan Wong 
# Email:wangle-it@bestpay.com.cn
# Release:
# 2015-8-17 create
# 2015-11-22 change test IP 
# 2015-12-4 change test IP 
case $1 in 
test)
	ip='172.26.10.59'
	;;
product)
	ip='132.97.124.165'
	;;
*)
	echo "Usage: $0 [test|product]"
	exit 1
	;;
esac
me=$(id | awk -F '[=(]' '{print $2}')
if [ $me -eq 0 ]
then
  cmdpre=''
else
  cmdpre='sudo '
fi

release=$(cat /etc/redhat-release |awk '{print $7}')
arch=${release%.*}

case $release in
"6.0")
	vars=rhel6-6
	;;
"6.1")
	vars=rhel6-1
	;;
"6.2")
	vars=rhel6-6
	;;
"6.3")
	vars=rhel6-3
	;;
"6.4")
	vars=rhel6-6
	;;
"6.5")
	vars=rhel6-6
	;;
"6.6")
	vars=rhel6-6
	;;
"6.7")
	vars=rhel6-7
	;;
"7.1")
	vars=rhel7-1
	;;
"7.2")
	vars=rhel7-1
	;;
*)
	echo 'ERROR,please check the server is RHEL6/7!'
	exit 2
	;;
esac
$cmdpre mv /etc/yum.repos.d/* /tmp
echo $vars > /tmp/releaserver_$$
$cmdpre mv /tmp/releaserver_$$ /etc/yum/vars/releaserver
$cmdpre chown root:root /etc/yum/vars/releaserver

cat >/tmp/rhel.repo_$$<<EOF
[rhel-x86_64]
name=Red Hat Enterprise Linux $vars x86_64 - Source
baseurl=http://$ip/\$releaserver
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

[Epel-x86_64]
name=Epel Packages x86_64
baseurl=http://$ip/epel/${arch}/x86_64
enabled=1
gpgcheck=1
gpgkey=http://$ip/epel/RPM-GPG-KEY-EPEL-${arch}

[Ius-x86_64]
name=Ius Packages x86_64
baseurl=http://$ip/ius/${arch}/x86_64
enabled=1
gpgcheck=1
gpgkey=http://$ip/GPG-KEY/IUS-COMMUNITY-GPG-KEY

[Elrepo-x86_64]
name=Elrepo Packages x86_64
baseurl=http://$ip/elrepo/elrepo/el${arch}/x86_64
enabled=0
gpgcheck=1
gpgkey=http://$ip/GPG-KEY/RPM-GPG-KEY-elrepo.org

[rhel-${arch}-server-rpms]
name=rhel-${arch}-server-rpms
baseurl=http://$ip/rhel-official/rhel-${arch}-server-rpms/Packages
enabled=1
gpgcheck=1
gpgkey=http://$ip/GPG-KEY/RPM-GPG-KEY-redhat-release

[rhel-${arch}-server-optional-rpms]
name=rhel-${arch}-server-optional-rpms
baseurl=http://$ip/rhel-official/rhel-${arch}-server-optional-rpms/Packages
enabled=1
gpgcheck=1
gpgkey=http://$ip/GPG-KEY/RPM-GPG-KEY-redhat-release

[rhel-${arch}-server-extras-rpms]
name=rhel-${arch}-server-extras-rpms
baseurl=http://$ip/rhel-official/rhel-${arch}-server-extras-rpms/Packages
enabled=1
gpgcheck=1
gpgkey=http://$ip/GPG-KEY/RPM-GPG-KEY-redhat-release

[rhel-${arch}-server-supplementary-rpms]
name=rhel-${arch}-server-supplementary-rpms
baseurl=http://$ip/rhel-official/rhel-${arch}-server-supplementary-rpms/Packages
enabled=1
gpgcheck=1
gpgkey=http://$ip/GPG-KEY/RPM-GPG-KEY-redhat-release

[rhel-${arch}-server-debug-rpms]
name=rhel-${arch}-server-debug-rpms
baseurl=http://$ip/rhel-official/rhel-${arch}-server-debug-rpms/Packages
enabled=0
gpgcheck=1
gpgkey=http://$ip/GPG-KEY/RPM-GPG-KEY-redhat-release

[rhel-${arch}-server-optional-debug-rpms]
name=rhel-${arch}-server-optional-debug-rpms
baseurl=http://$ip/rhel-official/rhel-${arch}-server-optional-debug-rpms/Packages
enabled=0
gpgcheck=1
gpgkey=http://$ip/GPG-KEY/RPM-GPG-KEY-redhat-release

[saltstack]
name=saltstack packages
baseurl=http://$ip/saltstack/rhel${arch}
enabled=1
gpgcheck=1
gpgkey=http://$ip/saltstack/rhel${arch}/SALTSTACK-GPG-KEY.pub
EOF


$cmdpre mv /tmp/rhel.repo_$$ /etc/yum.repos.d/rhel.repo
$cmdpre chown root:root /etc/yum.repos.d/rhel.repo
$cmdpre yum clean all &>/dev/null
echo "Yum configuring..."
$cmdpre yum makecache &>/dev/null
if [ $? -eq 0 ]
then
	echo "Yum config [ok]"
	exit 0
else
	echo "Yum config [fail]"
	exit 1
fi
