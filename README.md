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


## Prerequisites ##

* Ubuntu 16.04 base install virtual machine
* Working Cuckoo Sandbox virtual machines
* Linux host with Virtual Box
* Postfix installation on the host
* you know what you're doing


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
* installed and replicated your VMs on your VM host
* configured networking properly
* configured some mail thing on the host
* configured cuckoo properly to know and use your VMs

Then it's your turn to do the following:
* set your own FQDN (``/etc/hosts``)
* configure VM host to allow SSH connections from ``$HOSTNAME (.ssh/authorized_keys)``
* configure static IP in ``/etc/network/interfaces``
* reboot & snapshot

That's it well done

Thanks
have a nice day


### Do more ###

Then carry on reading [REAMDE-postinstallation.md](REAMDE-postinstallation.md)

AND find useful scripts in [utils](utils)


## Copyright ##

Copyright (C) 2016-2018 science + computing ag
