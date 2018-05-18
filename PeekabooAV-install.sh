#!/bin/bash
#
#
#   PeekabooAV Installer
#
#   this installer is work in progress
#   it has two purposes
#   - an easy way to have a fast installation
#   - documentation on how to set things up
#
#   it can also be used to update an installation
#
#
#   by felix bauer
#  felix.bauer@atos.net
#
# 23.08.2017
#
# Copyright (C) 2016-2018 science + computing ag
#
#

#
# This install script describes and performs a basic installation 
# of PeekabooAV
#

# The following function will clear all buffered stdin.  (See
# http://compgroups.net/comp.unix.shell/clear-stdin-before-place-read-a/507380)
fflush_stdin() {
    local dummy=""
    local originalSettings=""
    originalSettings=`stty -g`
    stty -icanon min 0 time 0
    while read dummy ; do : ; done
    stty "$originalSettings"
}

# The following code is just to have the owl and info scroll bye slowly.
while IFS= read -r line; do
  printf '%s\n' "$line"
  sleep .1
done << EOF
                                                                                
                         ==                             =                       
                         ========                 =======                       
                           ===========?     ===========                         
                             ========================                           
                            ==       ========       ===                         
                           =           ====           =                         
                          +=     ?     ====     ?     ==                        
                          ==           =,,=           ==                        
                           =          ,,,,,,,         =+                        
                           ==         =,,,,=         ==                         
                            +====+=======,====== =====                          
                            ==========================                          
                          ==============================                        
                         ===============77===============                       
                         =========77777777777777+========                       
                         ======77777777777777777777======                       
                         =====7777777777777777777777=====                       
                          ===777777777777777777777777====                       
                          ===7777777777777777777777777==                        
                           ==7777777777777777777777777=                         
                           +=777777777777777777777777==                         
                            ==77777777777777777777777=                          
                             ==777777777777777777777=                           
                              +=7777777777777777777=                            
                                =7777777777777777=                              
                                 ==777777777777==                               
                                    ==777777==                                  
                            ,,,,,,::::::==::::::,,,,,,                          
                    ,,,,,,,,,,,,,,,              ,,,,,,,,,,,,,                  
              ,,,,,,,,                                        ,,,,,,            
          ,,,,,                                                      ,,,        
       ,,,                                                                      
    ,                                                                           
                                                                                
                                                                                
Welcome to the PeekabooAV installer
===================================

we assume the following:
- you want to install or update PeekabooAV
- this is a Ubuntu 16.04 VM
- is fully updated (apt-get upgrade)
- nothing else runs on this
- you run this installer as root
- you know what you're doing!

If any of these is not the case please hit Ctrl+c

Press enter to continue

EOF

# Discard all input in buffer.
fflush_stdin

# Read 'Press enter ..'
read

if [ $(id -u) != 0 ]; then
   echo "ERROR: $(basename $0) needs to be run as root" >&2
   exit 1
fi

# Refresh package repositories.
apt-get update -y
if [ $? != 0 ]; then
   echo "ERROR: the command 'apt-get update' failed. Please fix manually" >&2
   exit 1
fi
# Install python and ansible

apt-get install -y python2.7
if [ $? != 0 ]; then
   echo "ERROR: the installation of 'python2.7' failed. Please fix manually" >&2
   exit 1
fi

apt-get install -y python-pip
if [ $? != 0 ]; then
   echo "ERROR: the installation of 'python-pip' failed. Please fix manually" >&2
   exit 1
fi

LC_ALL=C pip install ansible
if [ $? != 0 ]; then
   echo "ERROR: the installation of 'ansible failed. Please fix manually" >&2
   exit 1
fi
ANSIBLE_INVENTORY=$(dirname $0)/ansible-inventory
ANSIBLE_PLAYBOOK=$(basename $0 .sh).yml

if [ ! -r "$ANSIBLE_INVENTORY" ]; then
    echo "ERROR: ansible inventory file "$ANSIBLE_INVENTORY" not found" >&2
    exit 1
fi

if [ ! -r "$ANSIBLE_PLAYBOOK" ]; then
    echo "ERROR: ansible playbook "$ANSIBLE_PLAYBOOK" not found" >&2
    exit 1
fi
ansible-playbook -i "$ANSIBLE_INVENTORY" "$ANSIBLE_PLAYBOOK"

if [ $? != 0 ];then
   echo "ERROR: 'ansible-playbook' failed. Please fix manually" >&2
   exit 1
fi
# Clear screen.
clear

cat << EOF
Things are Done
===============

now there is a user called peekaboo whose home is at /var/lib/peekaboo

assuming you've done this:
- installed and replicated your VMs on your vmhost
- configured networking properly
- configured some mail thing on the host
- configured cuckoo properly to know and use your VMs

now it's your turn to do the following:
- set your own fqdn (/etc/hosts)
- configure vmhost to allow SSH connections from $HOSTNAME (.ssh/authorized_keys)
- configure static ip in /etc/network/interfaces
- reboot & snapshot

That's it well done

Thanks
have a nice day
EOF


