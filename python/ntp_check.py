#!/usr/bin/python
 #-*- coding: GB18030 -*-
import paramiko
import threading
import time
import csv



def ssh2(ip,username,passwd):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip,22,username,passwd,timeout=5)
        path="/daycheck/ntp"
        date = time.strftime('%Y%m%d',time.localtime(time.time()))
	filename = "ntpcheck_"+date+".csv"
        filepath = path + "/"+filename
        offset=" "
        serviceip=" "
        remote_ip=" "
        f = open(filepath,'a+')
        writer = csv.writer(f)
        stdin, stdout, stderr = ssh.exec_command("/sbin/service  ntpd status")
        out = stdout.read()
        if out =="":
            stdin, stdout, stderr = ssh.exec_command(" /bin/rpm -qa ntp")
            out = stdout.read()
            if out == "":
                 out ="Service isn't installed"
            else:
                out = "Service has been installed but not started"
        else:

            stdin, stdout, stderr = ssh.exec_command("   /usr/sbin/ntpq -np |awk '{print $9}'|sed '1,2d'|awk '(NR==1){print}'")
            offset=stdout.read()
            if float(offset) >1000:
                out = "Time difference over 1000 ms"
            else:
                out = "ok"
	    stdin, stdout, stderr = ssh.exec_command("  /usr/sbin/ntpq -np | awk '{print $1}'|sed '1,2d'|cut -c 2- |head -1")
            remote_ip=stdout.read().strip()
	    if remote_ip  == "132.97.126.193" or  remote_ip  == "132.97.124.180" or remote_ip  == "132.97.124.181":
		 writer.writerow([ip,out,offset])
	    else :
                stdin, stdout, stderr = ssh.exec_command("   /bin/grep ^server /etc/ntp.conf | awk '{print $2}' ")
                serviceip = stdout.read()
                writer.writerow([ip,out,offset,remote_ip,serviceip])









        f.close()
        ssh.close()
    except :
        print '%s\tError\n'%(ip)


if __name__=='__main__':
    for line in open("/home/hostmember8/script/passfile"):
        ip= line.split(',')[0]
	username="maintain"
        passwd=line.split(',')[1].strip('\n')



        a=threading.Thread(target=ssh2,args=(ip,username,passwd))

        a.start()






