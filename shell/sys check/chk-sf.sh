#!/bin/bash

if [ ! -e /opt/VRTSvcs/bin/hastatus ]
then
    echo "Not have SF cluster"
else
#cluster health judge
node_num=$(sudo /opt/VRTSvcs/bin/hastatus -sum |grep -w A|wc -l)
node_run=$(sudo /opt/VRTSvcs/bin/hastatus -sum |grep -w A|grep RUNNING|wc -l)
res_num=$(sudo /opt/VRTSvcs/bin/hastatus -sum |grep -w B|wc -l)
res_run=$(sudo /opt/VRTSvcs/bin/hastatus -sum |grep -w B|grep ONLINE|wc -l)
llt_num=$(sudo /sbin/lltstat -n|sed 1,2d|wc -l)
llt_run=$(sudo /sbin/lltstat -n|grep OPEN|wc -l)
llt_link=$(sudo /sbin/lltstat -n|sed 1,2d|awk -F'[ *]+' '{print $5}'|wc -l)

if [ $node_num -eq $node_run ]
then
    echo "SF Cluster node health check :                 [ok]"
else
    echo "SF Cluster node health check :                 [fail]"
fi
if [ $res_num -eq $res_run ]
then
    echo "SF Cluster resource health check :             [ok]"
else
    echo "SF Cluster resource health check :             [fail]"
fi
if [ $llt_num -eq $llt_run ]
then
    echo "SF Cluster heartbeat health check :            [ok]"
else
    echo "SF Cluster heartbeat health check :            [fail]" 
fi
if [ $llt_num -eq $llt_link ]
then
    echo "SF Cluster heartbeat link count health check : [ok]"
else
    echo "SF Cluster heartbeat link count health check : [fail]"
fi

#echo "SF Cluster node status info :"
#sudo /opt/VRTSvcs/bin/hastatus -sum |grep -w A|awk '{print $2,$3}'
#echo "SF Cluster node resource status info :"
#sudo /opt/VRTSvcs/bin/hastatus -sum |grep -w B|awk '{print $3,$2,$6}'
#echo "SF Cluster heartbeat status info :"
#sudo /sbin/lltstat -nvv active
fi

#disk health judge
disk_num=$(sudo vxdisk list|grep hitachi|wc -l)
disk_run=$(sudo vxdisk list|grep hitachi|grep online|wc -l)
vol_num=$(sudo vxprint -v |grep -w v|wc -l)
vol_ena=$(sudo vxprint -v |grep -w v|grep ENABLED|wc -l)
vol_act=$(sudo vxprint -v |grep -w v|grep ACTIVE|wc -l)
plex_num=$(sudo vxprint -p |grep -w pl|wc -l)
plex_ena=$(sudo vxprint -p |grep -w pl|grep ENABLED|wc -l)
plex_act=$(sudo vxprint -p |grep -w pl|grep ACTIVE|wc -l)

if [ $disk_num -eq $disk_run ]
then
    echo "SF disk health check :                         [ok]"
else
    echo "SF disk health check :                         [fail]"
fi
if [ $vol_num -eq $vol_act -a $vol_num -eq $vol_act ]
then
    echo "SF volume health check :                       [ok]"
else
    echo "SF volume health check :                       [fail]"
fi
if [ $plex_num -eq $plex_ena -a $plex_num -eq $plex_act ]
then
    echo "SF plex health check :                         [ok]"
else
    echo "SF plex health check :                         [fail]"
fi

