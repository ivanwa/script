#!/usr/bin/python3
import sys
wwid='3600a0980'
if len(sys.argv) == 2:
        serial = sys.argv[1]
else:
        serial = input("Enter the Netapp's lun serial: ")
for c in serial:
        wwid += hex(ord(c)).replace('0x','')
print(wwid)
