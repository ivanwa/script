#!/bin/bash
#salt 'zaibbixdb113-2' cmd.script 'salt://script/host-chk-ntp.sh' template=jinja
{% if  grains['ip4_interfaces']['bond0']  is defined  %}
ip={{ grains['ip4_interfaces']['bond0'][0] }}
{% elif grains['ip4_interfaces']['eth0']  is defined %}
ip={{ grains['ip4_interfaces']['eth0'][0] }}
{% else %}
ip={{ grains['ip4_interfaces']['eth1'][0] }}
{% endif %}
NTPIP=(
132.97.126.193
132.97.124.180
132.97.124.181
)
result='fail'
offset='none'
note=''
service ntpd status &> /dev/null
if [ $? -ne 0 ]
then
    rpm -q ntp &> /dev/null
    if [ $? -ne 0 ]
    then
        note="Service isn't installed"
    else
        note='Service has been installed but not started'
    fi
else
    offset=$(ntpq -np 2>/dev/null |grep \*|awk '{print $9}')
    if [ -z "$offset" ]
    then
      offset='error'
      result='fail'
      note='NTP server error!'
    else
      if [ $(expr $offset \> 1000) -eq 0 ]
      then
          result='fail'
          note='Time difference over 1000 ms'
      else
          result='pass'
      fi
      remote=$(ntpq -np 2>/dev/null |grep \*|awk '{print $1}'|cut -c 2-)
      ipcheck=1
      for confip in ${NTPIP[@]}
      do
          if [[ "$confip" == "$remote" ]]
          then
              ipcheck=0
              break
          else
              ipcheck=1
          fi
      done
      if [ $ipcheck -eq 1 ]
      then
          conf="$(grep ^server /etc/ntp.conf|awk '{print $2}'|xargs)"
          note="Current NTP IP: $remote ;Config NTP IP: $conf"
      fi
    fi
fi
echo "${ip},${result},${offset},${note}"
