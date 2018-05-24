# VBoxManage API #

To control VirtualBox machines running on the host from within a virtual machine.

## vboxmanage ##

`vboxmanage` is a script that uses `SSH` to connect to the VM-host to execure `vboxmanage` there and control the installed virtual machines.

`vboxmanage.conf` configures `IP` and `username`.

## Microsoft Windows ##

It is possible to control VirtualBox on Windows via the `vboxmanageAPI.py` (basically a bind shell with some filtering)
