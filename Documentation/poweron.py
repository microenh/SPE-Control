###################################
#!/usr/bin/env python
# coding=utf-8

import serial
import sys
import time

def poweron():
   try:
       serEXP.open()
       serEXP.setDTR(False)
       serEXP.setRTS(True)
       time.sleep(1)
       serEXP.setDTR(True)
       serEXP.setRTS(False)
       serEXP.close()
   except:
       print 'Error opening USB port'

port = ""
if len(sys.argv) == 2:
       port = sys.argv[1]


if not port:
   print "Can't find the USB port"
   sys.exit(2)


serEXP = serial.Serial()
serEXP.port = port
serEXP.baudrate = 115200
serEXP.timeout  = 0.1

poweron()
