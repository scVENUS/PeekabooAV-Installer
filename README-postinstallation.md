Things to do after the installer finishes
=========================================

## Installer
Run the installer or mimic its actions. 

## Configure Cuckoo and VBox control
become cuckoo user to configure cuckoo and vbox control

`su - cuckoo`

vboxmanage is a wrapper script that connect either over SSH
 to the virtualisation host (linux) or vboxmanageAPI.py (windows)
 
`vim ~/vboxmanage.conf`

Make sure that the host ip equals the chosen ip of your peekaboo vm.

depending on the chosen method it is necessary to either run
the vboxmanageAPI.py or configure ssh-key authentication on
the virtualisation host

### Windows Host
The path has to be set every time the vboxmanageAPI script is started.
```
smbclient ... vbox/vboxmanageAPI.py ...
 PS> $env:Path += ";C:\Program Files\Oracle\VirtualBox\"
 PS> C:\Python27\python.exe .\vboxmanageAPI.py
```
If you do not use the default ip (10.0.2.2) for the peekaboo vm
add the new ip to the list of hosts in the script.

### Linux Host
```
scp vmhost/remote-command.sh ...
scp vmhost/authorized_keys.sample ...
scp /var/lib/cuckoo/.ssh/id\_ed25519.pub ...
```

### Later

Try running vboxmanage on the peekaboo vm.
It should display its help.

`vboxmanage`

## Configuration of Cuckoo

`cd /var/lib/cuckoo/.cuckoo/conf`

configure the available machines.
Make sure to set the correct IP address for cuckoo agent to
connect back to `resultserver_ip`

`vim virtualbox.conf`

If you use embed mode and depending on the size of your
installation you might want to adjust the number of cuckoo
processors (`$n`)

`vim /opt/peekaboo/bin/cuckooprocessor.sh`

For API mode, enable and start additional processor unit instances:

```
for i in $(seq 6 10) ; do \
    systemctl enable cuckoo-process@$i ; \
    systemctl start cuckoo-process@$i ; \
done
```
Or raise the value of `cuckoo_processors` in `group_vars/all.yml` and re-run the installer.

You can now start peekaboo
```
systemctl start peekaboo
systemctl status peekaboo
```

Use socat to connect to peekaboo and expect the greeting
```
su -s /bin/bash amavis
socat STDIN UNIX-CONNECT:/var/run/peekaboo/peekaboo.sock
```

At this point it's already possible to check files
type the following into the previous command to check the
file.

`[ { "full_name": "/var/lib/cuckoo/vboxmanage.conf" } ]`

## Amavis configuration
Set `$myhostname, $mydomain, $virus_admin, $notify_method`
and `$forward_method` according to your needs.
If postfix runs remotely `$inet_socket_bind` and `@inet_acl`
have to be adjusted.

`vim /etc/amavis/conf.d/50-user`

## Configure MTA (here described for the stand alone - demo setup)

To be able to more natively send emails into the system,
an MTA can be added in front of AMaViS.
It has to be configured to forward mails to AMaViS
for which some config file template exist in the installer's `postfix` directory.

**Note**: You are free to omit everything postfix related and talk smtp to
amavis directly.

You have to install and configure Postfix manually, it's not part of the
standard installation:
```
apt install postfix
```

Then copy over the configuration files:
```
cp main.cf /etc/postfix/
cp master.cf /etc/postfix/
vim /etc/postfix/main.cf
vim /etc/postfix/master.cf
echo "peekabooav-demo.int" > /etc/mailname
```

Restart postfix
```
systemctl restart postfix
systemctl status postifx
```

It's time to analyse the first email
```
./peekabooav-installer/utils/checkFileWithPeekaboo.py README.md
systemctl status peekaboo
```

For the exact Demo / stand alone setup run the following commands
```
cp hosts /etc/hosts
cp interfaces /etc/network/interfaces
systemctl restart networking
```

Manually start the first virtual machine and check if its available

`ping 192.168.56.101`

Now to start with behavioural analysis, switch to the cuckoo user:
```
su - cuckoo
```

The following command will return an ID, spinn up a VM and
ultimately produce a report

`/opt/cuckoo/bin/cuckoo submit /usr/share/icons/cab_view.png`

## Configure and start Cuckoo Web UI
Adjust the IP address it binds to

`vim /etc/systemd/system/cuckoohttpd.service`

and start
```
systemctl daemon-reload
systemctl start cuckoohttpd.service
```

Use your favourite browser and connect to port 8000 and 
check "Recent" for your analysis.

## Add Dovecot and Thunderbird

Dovecot and Thunderbird can be added as MDAs and MUAs, respectively to get a
feel from the end-user perspective:
```
apt install dovecot-imapd
```

For quick demo results change
`disable_plaintext_auth to no` in
`vim /etc/dovecot/conf.d/10-auth.conf`

Add user to group mail

`gpasswd -a felix mail`

Configure thunderbird:
```
felix@peekabooav-demo.int
imap 143 no connection security plain password
smpt 25 no connection security no authentication
```

## Analyse
```
Analyse: Now send an email to yourself
send another one with an attachment
have fun
goto Analyse
```
