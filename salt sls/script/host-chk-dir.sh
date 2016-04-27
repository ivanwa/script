#!/bin/bash
#salt 'zaibbixdb113-2' cmd.script 'salt://script/host-chk-dir.sh' template=jinja
{% if  grains['ip4_interfaces']['bond0']  is defined  %}
ip={{ grains['ip4_interfaces']['bond0'][0] }}
{% elif grains['ip4_interfaces']['eth0']  is defined %}
ip={{ grains['ip4_interfaces']['eth0'][0] }}
{% else %}
ip={{ grains['ip4_interfaces']['eth1'][0] }}
{% endif %}
checkdir=(
/tools
/data
)
result='pass'
note=''
for dir in ${checkdir[@]}
do
  perm=$(stat $dir|grep Uid|awk -F '[( /)]+' '{print $2}')
  user=$(stat $dir|grep Uid|awk -F '[( /)]+' '{print $6}')
  group=$(stat $dir|grep Uid|awk -F '[( /)]+' '{print $9}')
  if [[ "$user" != 'bestpay' || "$group" != 'bestpay'  ]]
  then
    result='fail'
  else
    case $dir in
      '/tools')
        if [[ "$perm" != '0700' ]]
        then
          result='fail'
        fi
      ;;
      '/data')
        if [[ "$perm" != '0750' ]]
        then
          result='fail'
        fi
      ;;
      *)
        note='Error check dir!'
      ;;
    esac
  fi
  if [[ $result == 'fail' ]]
  then
    note="$(echo $note)${dir}:${perm}:${user}:${group} "
  fi
done
echo "${ip},${result},${note}"
