# PeekabooAV Installer #

This repository provides scripts and configuration files to install/update and test a
Peekaboo installation.

The outcome is a virtual machine that takes email messages via AMaViS, processes
them with Peekaboo and Cuckoo Sandbox, and hands mail back to Postfix.

Necessary packages and source code is pulled and installed automatically.

Have a read of ``PeekabooAV-install.sh`` it contains lots of information and explanations.

Quick and easy, download ``pstrap.sh`` and run.
(It pulls the repo to ``/tmp`` and runs the installer)

Certainly it is possible to run the installer again if e.g. network timeouts have stoped
its execution. This installer can also be used as an updater, it implements tests and
replaces updated files and performes an installation of the latest PeekabooAV release.

A [video tutorial](https://www.youtube.com/watch?v=RO-P4kJEqLU) of the setup
process of a testing environment is also available.


## Prerequisites ##

* you want to install or update PeekabooAV
* this is a Ubuntu 18.04 VM
* /etc/hostname is a valid FQDN
* nothing else runs on this machine
* you run this installer as root
* you know what you're doing!


### This is what you type (copy - paste)
For a released version, e.g. 2.1
```
git clone -b v2.1 https://github.com/scVENUS/PeekabooAV-Installer
cd PeekabooAV-Installer/
./PeekabooAV-install.sh
```

Or for testing most resent changes of the repository
```
git clone https://github.com/scVENUS/PeekabooAV-Installer
cd PeekabooAV-Installer/
git clone https://github.com/scVENUS/PeekabooAV
./PeekabooAV-install.sh
```


Then carry on reading [README-postinstallation.md](README-postinstallation.md)
and of course the Cuckoo Sandbox [documentation](https://cuckoo.sh/docs/index.html).

AND find useful scripts in [utils](utils)


## Communication flow ##

```
Host:25 -> Postfix content_filter
VM:1024 -> AMaViS
  -> Peekaboo
-> Host:10025 Postfix
```

The MTA running on the host receives email and hands it over to AMaViS inside
the VM this then splits up content and attachments. Peekaboo then analysis those
files and reports back to AMaViS. Mail is then handed back to the host.


## When things are Done ##

There is a user called ``peekaboo`` whose home is at ``/var/lib/peekaboo``.

Assuming you've done this:
* you want to install or update PeekabooAV
* this is a Ubuntu 18.04 VM
* is fully updated (apt-get upgrade)
* apt working and package source available
* recent version of ansible is installed (>2.4 (in Ubuntu 16.04 use pip))
* /etc/hostname is a valid FQDN
* nothing else runs on this machine
* you run this installer as root
* you know what you're doing!

That's it well done

Thanks
have a nice day


### Do more ###


#### Check the components:

```
su - cuckoo -c "vboxmanage list vms"
su - cuckoo -c "cuckoo"
su - peekaboo -c "peekaboo -d -c /opt/peekaboo/etc/peekaboo.conf"
# if you upgrade from an earlier version you might have to delete the _meta table first
# should crash with "No such file or directory: '/run/peekaboo/peekaboo.pid'"
systemctl start peekaboo
ss -np | grep peekaboo
socat STDIN UNIX-CONNECT:/var/run/peekaboo/peekaboo.sock
systemctl status cuckoohttpd
systemctl status mongodb
http://127.0.0.1:8000 # cuckoo web UI analyse a file
python -m smtpd -n -c DebuggingServer 0.0.0.0:10025 &
utils/checkFileWithPeekaboo.py grafana/Screenshot-2018-1-17\ Grafana\ -\ PeekabooAV.png
```

## Showcase Pipeline

### Prerequisites ###

* you want to have an email pipeline to showcase or test PeekabooAV
* you can install and run [docker](https://docs[[.docker.com/get-docker/) and [docker-compose](https://docs.docker.com/compose/)

### This is what you type (copy - paste)

```
git clone https://github.com/scVENUS/PeekabooAV-Installer
cd PeekabooAV-Installer/
git clone https://github.com/scVENUS/PeekabooAV
```

Then carry on reading [pipeline/README.md](pipeline/README.md)


## Contributing ##
Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us. 


## Copyright ##

Copyright (C) 2016-2019 science + computing ag
