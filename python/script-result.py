#!/usr/bin/env python
#-*- coding: utf-8 -*-
import time
import csv

date=time.strftime('%Y%m%d%H%M',time.localtime(time.time()))
#result output file
fileout='/tmp/script-result-'+date+'.csv'
f = open(fileout,'a+')
writer = csv.writer(f)
#table
writer.writerow(['Minion ID','IP','result','offset','comment'])
#input file
file='/tmp/script.out'
output=open(file)
for line in output.readlines():
    line=eval(line)
    for minion, result in line.iteritems():
        #loop check value is dict
        #filter like: {'mosr-13-193': 'Minion did not return. [Not connected]'}
        if isinstance(result, str):
            continue
        note=result['stdout']
        splitnote=note.split(',')
        ip=splitnote[0]
        check=splitnote[1]
        offset=splitnote[2]
        comment=splitnote[3]
        writer.writerow([minion,ip,check,offset,comment])
