#!/bin/bash
#salt 'zaibbixdb113-2' cmd.script 'salt://script/host-chk-host.sh' template=jinja
{% if  grains['ip4_interfaces']['bond0']  is defined  %}
ip={{ grains['ip4_interfaces']['bond0'][0] }}
{% elif grains['ip4_interfaces']['eth0']  is defined %}
ip={{ grains['ip4_interfaces']['eth0'][0] }}
{% else %}
ip={{ grains['ip4_interfaces']['eth1'][0] }}
{% endif %}
host=$(hostname)
hostip=$(grep $host /etc/hosts|awk '{print $1}')
if [[ "$ip" != "$hostip" ]]
then
  result='fail'
  note="$(grep $host /etc/hosts)"
else
  result='pass'
  note=''
fi
echo "${ip},${result},${note}"
