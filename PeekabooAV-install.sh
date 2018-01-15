#!/bin/bash -fue
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
# Copyright (C) 2016-2017 science + computing ag
#
#

#
# This install script describes and performs a basic installation 
# of PeekabooAV
#

# `datadir` contains the location of the PeekabooAV-Installer
# repository clone
datadir=$(dirname $(readlink -e "$0"))
echo "Datadir set to $datadir"

# source config
[ -f ./PeekabooAV-install.conf ] && source ./PeekabooAV-install.conf

# Use the environment proxy settings.
http_proxy=${http_proxy:-}

# If no proxy is set yet try default.
if [ -z "$http_proxy" ]
then
  IP=10.0.2.4
  PORT=3128
  # Check if default proxy is reachable.
  # Like I said, this is just for me.
  if nc -w 1 -z ${IP} ${PORT}
  then
    export http_proxy=http://${IP}:${PORT}
    export https_proxy=http://${IP}:${PORT}
  fi
else
  echo "Proxy Setting"
  echo $http_proxy
fi

# In combination with the bash -fue in line 1 this will give information
# and crash this script on any uncaught error.
# That's also why some commands that are expected to return an error code
# are appended with `|| true`
trap '[ $? -gt 0 ] && echo "ERROR in $PWD/$0 at line $LINENO - you might want to run it again" >&2 && exit 1' 0

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
read -t .1 -n 10000 discard || true
# Read 'Press enter ..'
read

# Turn on debugging output of every comand run
set -x

# Check if running as root
[ $(id -u) -eq 0 ] || exit 1


cd /root

# Refresh package repositories.
apt-get update -y

# Install basic tools.
apt-get install -y vim ipython less iputils-ping socket netcat git curl socat

# Install Cuckoo dependencies.
apt-get install -y python python-pip python-dev libffi-dev libssl-dev
apt-get install -y python-virtualenv python-setuptools
apt-get install -y libjpeg-dev zlib1g-dev swig
apt-get install -y sqlite3 
apt-get install -y swig
apt-get install -y mongodb 

pip install -U pip 
pip install -U setuptools
pip install -U cuckoo
# TODO: since 2.0.4 yara is included
pip install -U yara-python==3.6.3

# Install tcpdump and set capability.
apt-get install -y tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump


# Install Peekaboo
cd /opt

# Skip if /opt/peekaboo already exists
if [ -d /opt/peekaboo ]
then
  cd /opt/peekaboo
  echo "Updating peekaboo code /opt/peekaboo" 
  git checkout master
  git pull
else
  # Use PeekabooAV code in Installer directory if present.
  if [ -d ${datadir}/peekabooav/ ]
  then
    git clone ${datadir}/peekabooav/ peekaboo
  else
    git clone https://github.com/scvenus/peekabooav peekaboo
  fi
fi
cd /opt/peekaboo
git checkout master
if [[ -z "$latest" ]]
then
  git checkout $(git tag | grep "^v" | tail -1)
else
  git checkout $latest
fi

# Create a new group peekaboo.
groupadd -g 150 peekaboo || echo "Couldn't add group, probably exists already"
# Create a new user peekaboo.
useradd -g 150 -u 150 -m -d /var/lib/peekaboo peekaboo || echo "Couldn't add user, probably exists already"

cd /opt/peekaboo

# If python-pyasn1 is already installed by apt uninstall it
apt-get autoremove -y python-pyasn1
# so it can be installed with pip as a requirement in the 
# correct version.
# remove comment as soon as requirements are fixed
pip install -r /opt/peekaboo/requirements.txt
# Run the Peekaboo install routine.
python setup.py install

# Copy systemd unit files to /etc.
cp -ub ${datadir}/systemd/peekaboo.service /etc/systemd/system
cp -ub ${datadir}/systemd/cuckoohttpd.service /etc/systemd/system
# Enable services to run on startup.
systemctl enable peekaboo
systemctl enable cuckoohttpd

# Place Peekaboo config in /opt/peekaboo
cp -ub ${datadir}/peekaboo/peekaboo.conf /opt/peekaboo


# Now place wrapper to run vboxmanage command on remote host.
# This is necessary to control vm start, stop and snapshot restore
# on the host from within the Peekaboo-VM.
cp -ub ${datadir}/vbox/vboxmanage /usr/local/bin
# The configuration contains IP address and username of the target
# user on the host that owns all virtual box vms.
cp -ub ${datadir}/vbox/vboxmanage.conf /var/lib/peekaboo/
chown peekaboo:peekaboo /var/lib/peekaboo/vboxmanage.conf

# Install ssh and setup ssh key for peekaboo user.
apt-get install -y ssh
[ -d /var/lib/peekaboo/.ssh ] || mkdir /var/lib/peekaboo/.ssh
chown peekaboo:peekaboo /var/lib/peekaboo/.ssh
# This key will have to be allowed on the host to authenticate the vm user.
[ -f /var/lib/peekaboo/.ssh/id_ed25519 ] || su -c "ssh-keygen -t ed25519 -f /var/lib/peekaboo/.ssh/id_ed25519 -P ''" peekaboo

# Setup chown2me.
# This is still necessary so Peekaboo can take ownership of
# the files created by amavis (patch).
touch /opt/peekaboo/chown2me.log
chown peekaboo:peekaboo /opt/peekaboo/chown2me.log
setcap cap_chown+ep /opt/peekaboo/bin/chown2me


# Initial run of Cuckoo to create directory structure in peekaboo $HOME.
[ -d /var/lib/peekaboo/.cuckoo ] || su -c "cuckoo" peekaboo

# Install cuckoo community signatures.
su -c "cuckoo community" peekaboo

# Copy config files for cuckoo
cp -ub ${datadir}/cuckoo/cuckoo.conf /var/lib/peekaboo/.cuckoo/conf/
cp -ub ${datadir}/cuckoo/virtualbox.conf /var/lib/peekaboo/.cuckoo/conf/
cp -ub ${datadir}/cuckoo/reporting.conf /var/lib/peekaboo/.cuckoo/conf/
cp -ub ${datadir}/cuckoo/cuckooprocessor.sh /opt/peekaboo/


# Install amavis and dependencies.
apt-get install -y amavisd-new && true
apt-get install -y arj bzip2 cabextract cpio file gzip lhasa nomarch pax rar unrar unzip zip zoo || true

# Get current version and patch amavisd-new.
cd /opt/peekaboo
if [ -d peekabooav-amavisd ]
then
  cd peekabooav-amavisd
  git pull
else
  git clone -b debian-find_config_files https://github.com/scvenus/peekabooav-amavisd
  cd peekabooav-amavisd
fi

cp amavisd /usr/sbin/amavisd-new

# Copy amavis configs to conf.d.
cp -ub ${datadir}/amavis/15-av_scanners /etc/amavis/conf.d/
cp -ub ${datadir}/amavis/15-content_filter_mode /etc/amavis/conf.d/
cp -ub ${datadir}/amavis/50-peekaboo /etc/amavis/conf.d/

# Restart amavis
systemctl restart amavis

# Allow access files and sockets for both.
gpasswd -a amavis peekaboo
gpasswd -a peekaboo amavis



# Install mysql database and setup users and databases.
apt-get install -y mariadb-server python-mysqldb
mysql < ${datadir}/mysql/mysql.txt || echo "Couldn't create dabases and users. Probably already exists"

# Restart services
systemctl restart peekaboo || echo "Peekaboo restart didn't work. Probably not configured yet"


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


