#!/bin/bash
#
# Name:host-pre-yum.sh
# Describe:Yum repo config
# Version:1.0
# Date:2015-8-17
# Author:Ivan Wong 
# Email:wangle-it@bestpay.com.cn
# Release:
# 2015-8-17 create
# 2015-11-22 change test IP 
# 2015-12-14 use official repo 
# 2016-01-29 add env path

#export PATH
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH

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
case $arch in
    "6")
        latest='rhel6-7'
        ;;
    "7")
        latest='rhel7-2'
        ;;
    *)
        echo 'ERROR,please check the server is RHEL6/7!'
        exit 2
        ;;
esac

echo "Yum configuring..."
$cmdpre mv /etc/yum.repos.d/* /tmp

cat >/tmp/rhel.repo_$$<<EOF
[rhel-x86_64]
name=Red Hat Enterprise Linux $vars x86_64 - Source
baseurl=http://$ip/$latest
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

[rhel-${arch}-rpms]
name=rhel-${arch}-rpms
baseurl=http://$ip/rhel-official/rhel-${arch}-server-rpms/Packages
enabled=1
gpgcheck=1
gpgkey=http://$ip/GPG-KEY/RPM-GPG-KEY-redhat-release

[rhel-${arch}-optional-rpms]
name=rhel-${arch}-optional-rpms
baseurl=http://$ip/rhel-official/rhel-${arch}-server-optional-rpms/Packages
enabled=1
gpgcheck=1
gpgkey=http://$ip/GPG-KEY/RPM-GPG-KEY-redhat-release

[rhel-${arch}-extras-rpms]
name=rhel-${arch}-extras-rpms
baseurl=http://$ip/rhel-official/rhel-${arch}-server-extras-rpms/Packages
enabled=1
gpgcheck=1
gpgkey=http://$ip/GPG-KEY/RPM-GPG-KEY-redhat-release

[rhel-${arch}-supplementary-rpms]
name=rhel-${arch}-supplementary-rpms
baseurl=http://$ip/rhel-official/rhel-${arch}-server-supplementary-rpms/Packages
enabled=1
gpgcheck=1
gpgkey=http://$ip/GPG-KEY/RPM-GPG-KEY-redhat-release

[rhel-${arch}-debug-rpms]
name=rhel-${arch}-debug-rpms
baseurl=http://$ip/rhel-official/rhel-${arch}-server-debug-rpms/Packages
enabled=0
gpgcheck=1
gpgkey=http://$ip/GPG-KEY/RPM-GPG-KEY-redhat-release

[rhel-${arch}-optional-debug-rpms]
name=rhel-${arch}-optional-debug-rpms
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
$cmdpre yum makecache &>/dev/null
if [ $? -eq 0 ]
then
	echo "Yum config [ok]"
	exit 0
else
	echo "Yum config [fail]"
	exit 3
fi
