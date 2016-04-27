#!/usr/bin/env python
#-*- coding: utf-8 -*-
import MySQLdb
import time
import csv
import sys


if len(sys.argv) != 2 :
    print "Usage: "+sys.argv[0]+" jid"
    #jid='20160421095531332247'
    sys.exit()
else:
    jid=sys.argv[1]


dbhost='172.26.10.63'
dbuser='system'
dbpasswd='q1w2e3r4'
db='salt'
port='3306'
conn=MySQLdb.connect(host=dbhost,user=dbuser,passwd=dbpasswd,db=db,port=3306)

date=time.strftime('%Y%m%d%H%M',time.localtime(time.time()))
#result output file
fileout='/tmp/db-result-'+date+'.csv'
f = open(fileout,'a+')
writer = csv.writer(f)
#table
writer.writerow(['Minion ID','IP','result','offset','comment','status'])
sql="SELECT `id`,`return`,`success` from salt_returns where jid="+jid
c=conn.cursor()
c.execute(sql)
results=c.fetchall()
for row in results:
    mid=row[0]
    mreturn=row[1]
    mreturn=eval(mreturn)
    moutput=mreturn['stdout']
    msuccess=row[2]
    #print mid,moutput,msuccess
    list=moutput.split(',')
    list.insert(0,mid)
    list.append(msuccess)
    writer.writerow(list)
conn.close()
