#!/usr/bin/env python
#-*- coding: utf-8 -*-
import time
import csv

date=time.strftime('%Y%m%d%H%M',time.localtime(time.time()))
#result output file
fileout='/tmp/state-result-'+date+'.csv'
f = open(fileout,'a+')
writer = csv.writer(f)
#table
writer.writerow(['Minion ID','IP','Checklist ','result','comment'])
#input file
file='/tmp/highstate.out'
output=open(file)
for line in output.readlines():
    #loop convent str to dict
    line=eval(line)
    minionid=line.keys()[0]
    for minion in line.keys():
        #loop check value is dict
        #filter like: {'mosr-13-193': 'Minion did not return. [Not connected]'}
        if isinstance(line[minion],str) :
            continue
        result=line[minion]
        #loop get items
        for item in result.keys():
            itemid=result[item]['name']
            note=result[item]['changes']['stdout']
            #note=xx.xx.xx.xx,pass,hahaha
            splitnote=note.split(',')
            ip=splitnote[0]
            check=splitnote[1]
            comment=splitnote[2]
            writer.writerow([minionid,ip,itemid,check,comment])
            #print minionid +","+  itemid +","+ note
