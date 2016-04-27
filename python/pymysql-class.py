#!/usr/bin/env python
#-*- coding: utf-8 -*-
import MySQLdb
import time

class Mysql:
    #define errcode,instance,connection,cursor
    errcode = ''
    errmsg = ''
    _instance = None
    _conn = None
    _cur = None
    #DB connection timeout
    _TIMEOUT = 30
    _timecount = 0

    def __init__(self, host, user, passwd, port=3306, charset="utf8"):
        self.host = host
        self.user = user
        self.passwd = passwd
        self.port = port
        self.charset = charset
        try:
            self._conn = MySQLdb.connect(host=self.host,port=self.port,user=self.user,passwd=self.passwd)
            #disable autocommit
            self._conn.autocommit(False)
            #set charset utf-8
            self._conn.set_character_set(self.charset)
            self._cur=self._conn.cursor()
            self._instance = MySQLdb
        except MySQLdb.Error, e:
            self.errcode = e.args[0]
            errmsg = "Mysql Error %d: %s", e.args[0], e.args[1]
            print errmsg
            if self._timecount < self._TIMEOUT:
                interval = 5
                self._timecount += interval
                time.sleep(interval)
                return self.__init__(self, host, user, passwd, port=3306, charset="utf8")
            else:
                raise Exception(errmsg)

    #release resource
    def __del__(self):
        try:
            self._cur.close()
            self._conn.close()
        except:
            pass

    #close db
    def close(self):
        self.__del__()

    #select db
    def selectDb(self, db):
        try:
            result=self._conn.select_db(db)
        except MySQLdb.Error, e:
            print("Mysql Error %d: %s" % (e.args[0], e.args[1]))
            return False
        return result

    #query sql
    def query(self, sql):
        try:
            return self._cur.execute(sql)
        except MySQLdb.Error, e:
            print("Mysql Error %d: %s" % (e.args[0], e.args[1]))
            return False

    #insert sql
    def insert(self, sql):
        try:
            self._cur.execute(sql)
            self._conn.commit()
            return self._cur.lastrowid
        except MySQLdb.Error, e:
            self.errcode = e.arg[0]
            print("Mysql Error %d: %s" % (e.args[0], e.args[1]))
            return False

    #update sql
    def update(self, sql):
        try:
            result=self._cur.execute(sql)
            self._conn.commit()
            return result
        except MySQLdb.Error, e:
            self.errcode = e.arg[0]
            print("Mysql Error %d: %s" % (e.args[0], e.args[1]))
            return False

    #delete sql
    def delete(self, sql):
        try:
            result=self._cur.execute(sql)
            self._conn.commit()
            return result
        except MySQLdb.Error, e:
            self.errcode = e.arg[0]
            print("Mysql Error %d: %s" % (e.args[0], e.args[1]))
            return False

    #return one row
    def fetchRow(self):
        return self._cur.fetchone()

    #return all rows
    def fetchAll(self):
        return self._cur.fetchall()

    #get last insert id
    def getLastInsertId(self):
        return self._cur.lastrowid

    #get rows count
    def getRowCount(self):
        return self._cur.rowcount

    #transaction commit
    def commit(self):
        self._conn.commit()

    #transaction rollback()
    def rollback(self):
        self._conn.rollback()


"""
#init sample
if __name__ == '__main__':
    host = '172.26.10.63'
    user = 'salt'
    passwd = 'q1w2e3r4'
    db = 'salt'
    connection=Mysql(host, user, passwd)
    connection.selectDb(db)
    sql="SELECT `id`,`return`,`success` from salt_returns where jid='20160421095531332247'"
    connection.query(sql)
    result=connection.fetchAll()
    result2=connection.fetchRow()
    print result
    print result2
    connection.close()
"""
