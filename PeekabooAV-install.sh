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

if [[ "$1" != "--quiet" ]]
then
    shift
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
- apt working and package source available
- recent version of ansible is installed (>2.4 (not available via apt)
- /etc/hostname is a valid FQDN
- nothing else runs on this machine
- you run this installer as root
- you know what you're doing!

If any of these is not the case please hit Ctrl+c

Press enter to continue

EOF

    # Discard all input in buffer.
    fflush_stdin

    # Read 'Press enter ..'
    read
fi


if [ $(id -u) != 0 ]; then
   echo "ERROR: $(basename $0) needs to be run as root" >&2
   exit 1
fi

# Check if hostname fqdn is properly set and resolves
if ! hostname --fqdn | grep -q "\." > /dev/null 2>&1
then
   echo "ERROR: hostname FQDN not explicitly assigned"
   exit 1
fi

# Check for installed ansible
if ! command -v ansible
then
   echo "ERROR: ansible missing"
   exit 1
fi

# Check for installed ansible
if dpkg -l ansible > /dev/null 2>&1
then
   echo "WARNING: ansible is already installed with apt (apt-get purge ansible)"
fi

ansibleversion=$(ansible --version | head -n 1 | grep -o "[0-9\.]*")
IFS='.' read -r -a ansibleversionarray <<< "$ansibleversion"
# check major version
if [[ ${ansibleversionarray[0]} -eq 2 ]]
then
  # check minor version
  if [[ ${ansibleversionarray[1]} -lt 5 ]]
  then
     echo "ERROR: ansible version (${ansibleversion}) too old, at least version 2.5 required"
     exit 1
  fi
else
  echo "ERROR: ansible version likely not compatable, at least version 2.5 required"
  exit 1
fi

# Refresh package repositories.
apt-get update -y
if [ $? != 0 ]; then
   echo "ERROR: the command 'apt-get update' failed. Please fix manually" >&2
   exit 1
fi

# Check for SYSTEMD module
if ! ansible-doc systemd 2>/dev/null | grep -q SYSTEMD
then
   echo "ERROR: ansible version maybe too old, SYSTEMD module missing"
   exit 1
fi

if [ ! -d PeekabooAV/.git ]
then
    echo "ERROR: no local copy of PeekabooAV found"
    echo "run 'git submodule init' and 'git submodule update' or place files in directory 'PeekabooAV'"
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
- configure vmhost to allow SSH connections from $HOSTNAME (.ssh/authorized_keys)
- configure static ip in /etc/network/interfaces
- check dataflow through mail, amavis, peekaboo, cuckoo
- reboot & snapshot

That's it well done

Thanks
have a nice day
EOF
