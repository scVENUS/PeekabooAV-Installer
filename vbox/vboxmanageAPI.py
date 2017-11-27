"""
Agent to run on the Windows VM host for Peekaboo to
connect back and control VMs.

It's a hack if you can't have a native Linux

testing only!


By Felix Bauer

felix.bauer@atos.net

8.11.2017



# in powershell
$env:Path += ";C:\Program Files\Oracle\VirtualBox\"
C:\Python27\python.exe .\vboxmanageAPI.py

"""


import subprocess
import socket
import sys
import os
import re
from threading import Thread

host = "0.0.0.0"; #! address to bind on.
src  = ("127.0.0.1","10.0.2.15");
port = int(4444);


def runstuff(c, addr):
	data=c.recv(1024);
	if len(data) > 3:
		print ":"+data+":";
	# vboxmanage showvminfo cuckoo101 --machinereadable
	m = re.search('^(vboxmanage [a-z0-9- ]*)$', data)
	if not m:
		print m
		c.send("Illegal command\n")
		c.shutdown(socket.SHUT_RDWR)	
		s.close()
		print "child done"
		return

	for line in os.popen(data):
		c.send(line);
	c.shutdown(socket.SHUT_RDWR)	
	s.close()
	print "child done"


while True:
	try:
		s = socket.socket(socket.AF_INET,socket.SOCK_STREAM);
		s.bind((host,port));
		s.listen(4);
		while True:
			print "waiting for connection"
			c,addr=s.accept();
			print addr;
			if addr[0] not in src:
				c.send("Access denied, bye\n")
				print "Access denied"
				c.shutdown(socket.SHUT_RDWR)
				s.close()
				break
			Thread(target=runstuff,args=[c,addr]).start()

	except KeyboardInterrupt:
		c.send("\n\t[ctrl+c] server forcely closed by Victim.\n");
		s.close();
		sys.exit(1);
	except socket.error:
		print "\n\t[error] Address { %s : %s } already in use."%(host,port);
		print "\t[error] just wait a bit until we correct it for you.";
		s.close();
		print "\n\ntrying again ....";
	except OSError:
		print "\n\t[error] Address { %s : %s } already in use."%(host,port);
		print "\t[error] just wait a bit until we correct it for you.";
		s.close();
		print "\n\ntrying again ....";
