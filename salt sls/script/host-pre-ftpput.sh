#!/bin/bash
SRCID=$1
SRCPATH=$2
SRCNAME=$3
DSTID=$4
DSTPATH=$5
#host-pre-ftpput.sh test-yum-10-59 /root yum-init.sh test-log01-10-61 /tmp
CACHEPATH='/var/cache/salt/master/minions/'
#test-yum-10-59/files/root/yum-init.sh


salt "$SRCID" cp.push "${SRCPATH}/${SRCNAME}"
srcfile="${CACHEPATH}${SRCID}/files/${SRCPATH}/${SRCNAME}"
if [ -f $srcfile ]
then
  mv $srcfile /srv/salt/temp
else
  echo 'Msg:push file fail!'
  exit 1
fi
salt "$DSTID" cp.get_file salt://temp/${SRCNAME} ${DSTPATH}/${SRCNAME}
if [ $? -eq 0 ]
then
  rm -rf "/srv/salt/temp/${SRCNAME}" &>/dev/null
  echo 'Msg:file put success!'
else
  echo 'Msg:get file fail!'
fi
