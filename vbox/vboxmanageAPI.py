"""
Agent to run on the Windows VM host for Peekaboo to
connect back and control VMs.

It's a hack if you can't have a native Linux

testing only!


By Felix Bauer

felix.bauer@atos.net

8.11.2017
29.06.2017



# in powershell
$env:Path += ";C:\Program Files\Oracle\VirtualBox\"
C:\Python27\python.exe .\vboxmanageAPI.py

"""


import SocketServer
import socket
import os
import re


# address to bind to.
host = "0.0.0.0";
# allowed source IPs
src  = ("127.0.0.1","10.0.2.15");
port = int(4444);
# allow only control over VMs with prefix
machineprefix = "(cuckoo|list)";



class VBoxManageAPI(SocketServer.ThreadingTCPServer):
    def __init__(self, bind_addr, port,
                 request_handler,
                 bind_and_activate=True):
        SocketServer.ThreadingTCPServer.__init__(
            self, (bind_addr, int(port)),
            request_handler,
            bind_and_activate=bind_and_activate
        )
        print('[+] Listening: %s on port %s' % (bind_addr, port))

    def server_close(self):
        print('[-] Shutting down VBoxManageAPI.')
        return SocketServer.ThreadingTCPServer.server_close(self)


class VBoxManageAPIHandler(SocketServer.BaseRequestHandler):
    def handle(self):
        if self.client_address[0] in src:
            print('[-] Connection from %s' % self.client_address[0])
        else:
            print('[!] Reject connection from %s' % self.client_address[0])
            return

        command = self.request.recv(1024).rstrip()
        print('[-] Got request to execute %s' % command)

        # vboxmanage showvminfo cuckoo101 --machinereadable
        m = re.search('^(vboxmanage [a-z0-9- ]*%s[A-Za-z0-9- ]*)$' % machineprefix, command)
        if m:
            print('[-] Executing "%s"' % command)
            for line in os.popen(command):
                self.request.send(line)
        else:
            self.request.sendall('> Illegal command "%s".' % command)


if __name__ == '__main__':
    server = VBoxManageAPI(
        host, port,
        VBoxManageAPIHandler
    )
    try:
        server.serve_forever()
    except OSError:
        print('[!] Address already in use.')
    except socket.error:
        print('[!] Address already in use.')
    except KeyboardInterrupt:
        server.shutdown()
        print('[!] Server terminated by user.')
    finally:
        server.server_close()
