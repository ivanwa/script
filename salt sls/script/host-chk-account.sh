#!/bin/bash
#salt 'zaibbixdb113-2' cmd.script 'salt://script/host-chk-account.sh' template=jinja
{% if  grains['ip4_interfaces']['bond0']  is defined  %}
ip={{ grains['ip4_interfaces']['bond0'][0] }}
{% elif grains['ip4_interfaces']['eth0']  is defined %}
ip={{ grains['ip4_interfaces']['eth0'][0] }}
{% else %}
ip={{ grains['ip4_interfaces']['eth1'][0] }}
{% endif %}
mature=12
list=$(awk -F: '$5 == 99999 || $5 ~ /^$/ {next}{if(($2 !~ /^!/) && (($5 - (int(systime()/86400) - $3)) <= 12)) printf ("%s:%d\n",$1,$5 - (int(systime()/86400) - $3))}' /etc/shadow)
if [ -n "$list" ]
then
    echo "${ip},fail,$(echo $list|xargs)"
else
    echo "${ip},pass,"
fi
