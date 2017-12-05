#!/usr/bin/env python2


# test with
# python -m smtpd -n -c DebuggingServer 0.0.0.0:10025


import smtplib
import socket
from sys import argv
import pwd
import os
from os.path import basename
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.utils import COMMASPACE, formatdate


def send_mail(send_from, send_to, subject, text, files=None,
              server="127.0.0.1", port="25"):
    assert isinstance(send_to, list)

    msg = MIMEMultipart()
    msg['From'] = send_from
    msg['To'] = COMMASPACE.join(send_to)
    msg['Date'] = formatdate(localtime=True)
    msg['Subject'] = subject

    msg.attach(MIMEText(text))

    for f in files or []:
        with open(f, "rb") as fil:
            part = MIMEApplication(
                fil.read(),
                Name=basename(f)
            )
        # After the file is closed
        part['Content-Disposition'] = 'attachment; filename="%s"' % basename(f)
        msg.attach(part)

    #print msg.as_string()

#    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#
#    s.connect((server, port))
#    data = s.recv(1024)
#    print data
#
#    print "HELO %s" % host
#    s.sendall("HELO %s" % host)
#    data = s.recv(1024)
#    print(data)
#
#    print "MAIL FROM: <%s>" % send_from
#    s.sendall("MAIL FROM: <%s>" % send_from)
#    data = s.recv(1024)
#    print(data)
#
#    print "RCPT TO: <%s>" % send_to
#    s.sendall("RCPT TO: <%s>" % send_to)
#    data = s.recv(1024)
#    print(data)
#
#    print "DATA"
#    s.sendall("DATA")
#    data = s.recv(1024)
#    print(data)
#
#    s.sendall(msg.as_string())
#    while 1:
#        data = s.recv(1024)
#        print(data)
#        if not data: break
#    s.senall(".")
#    s.close()

    smtp = smtplib.SMTP(server,port)
    smtp.sendmail(send_from, send_to, msg.as_string())
    smtp.close()




user=pwd.getpwuid(os.getuid()).pw_name
host=socket.gethostname()

send_mail("%s@%s" % (user, host),
        ["scan@peekaboohost"],
        "Check this for me pls",
        "Are the attached files malicious?",
#        argv[1:], "192.168.56.5", 10024)
        argv[1:], "127.0.0.1", 10024)

