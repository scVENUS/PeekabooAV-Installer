#!/bin/bash -fue
#
#
#   PeekabooAV installer
#
#   by felix bauer
#  felix.bauer@atos.net
#
# 23.08.2017
#
# Copyright (C) 2016-2017 science + computing ag
#
#

datadir=$(pwd)
http_proxy=${http_proxy:-}

if [ -z "$http_proxy" ]
then
  IP=10.0.5.156
  PORT=3128
  if nc -w 1 -z ${IP} ${PORT}
  then
    export http_proxy=http://${IP}:${PORT}
    export https_proxy=http://${IP}:${PORT}
  fi
else
  echo "Proxy Setting"
  echo $http_proxy
fi


trap '[ $? -gt 0 ] && echo "ERROR in $PWD/$0 at line $LINENO" >&2 && exit 1' 0

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
- this is a Ubuntu 16.04 VM
- ist is fully updated
- nothing else runs on this
- you run this installer as root
- you know what you're doing

If any of these is not the case please hit Ctrl+c

Press enter to continue

EOF

read -t .1 -n 10000 discard || true
read

set -x

[ $(id -u) -eq 0 ] || exit 1


cd /root

apt-get update -y


# install base tools
apt-get install -y vim ipython less iputils-ping socket netcat git curl

# install cuckoo
apt-get install -y python python-pip python-dev libffi-dev libssl-dev
apt-get install -y python-virtualenv python-setuptools
apt-get install -y libjpeg-dev zlib1g-dev swig
apt-get install -y sqlite3 
apt-get install -y swig
apt-get install -y mongodb 


pip install -U pip 
pip install -U setuptools
pip install -U cuckoo
pip install -U yara-python==3.6.3


apt-get install -y tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump



# install peekaboo
cd /opt

if [ -d /opt/peekaboo ]
then
  echo "Reusing peekaboo code /opt/peekaboo" 
else
  if [ -d ${datadir}/peekabooav-gitlab/ ]
  then
    git clone ${datadir}/peekabooav-gitlab/ peekaboo
  else
    git clone https://github.com/scvenus/peekabooav peekaboo
  fi
fi

# git remote add gitlab https://10.108.245.48/secsol/PeekabooAV.git
# git -c http.sslVerify=false pull gitlab development


groupadd -g 150 peekaboo || echo "Couldn't add group, probably exists already"
useradd -g 150 -u 150 -m -d /var/lib/peekaboo peekaboo || echo "Couldn't add user, probably exists already"


cd peekaboo

apt-get autoremove python-pyasn1
#pip install pyasn1==0.3.3
python setup.py install


# allow peekaboo/cuckoo to write to log db and storage directory
#mkdir /opt/cuckoo/log /opt/cuckoo/db /opt/cuckoo/storage
#chown -R peekaboo:peekaboo /opt/cuckoo/log /opt/cuckoo/db /opt/cuckoo/storage /opt/cuckoo/data


# add directories for peekaboo to put socket, pid file and database
#mkdir /var/run/peekaboo /var/lib/peekaboo
#chown -R peekaboo:peekaboo /var/run/peekaboo /var/lib/peekaboo

cp ${datadir}/peekaboo.service /etc/systemd/system
cp ${datadir}/cuckoohttpd.service /etc/systemd/system
cp ${datadir}/peekaboo.conf /opt/peekaboo
systemctl enable peekaboo
systemctl enable cuckoohttpd


# wrapper to run vboxmanage command on remote host
cp ${datadir}/vboxmanage /usr/local/bin
apt-get install -y ssh
[ -d /var/lib/peekaboo/.ssh ] || mkdir /var/lib/peekaboo/.ssh
chown peekaboo:peekaboo /var/lib/peekaboo/.ssh
su -c "ssh-keygen -t ed25519 -f /var/lib/peekaboo/.ssh/id_ed25519 -P ''" peekaboo
cp ${datadir}/vboxmanage.conf /var/lib/peekaboo/

touch /opt/peekaboo/chown2me.log
chown peekaboo:peekaboo /opt/peekaboo/chown2me.log
setcap cap_chown+ep /opt/peekaboo/bin/chown2me


# initial run of cuckoo
[ -d /var/lib/peekaboo/.cuckoo ] || su -c "cuckoo" peekaboo
# install cuckoo community signatures
#if [ -n "$http_proxy" ]
#then
  su -c "cuckoo community" peekaboo
#else
#  su -c "http_proxy=$http_proxy https_proxy=$https_proxy cuckoo community" peekaboo
#fi

# copy config for cuckoo
cp ${datadir}/cuckoo.conf /var/lib/peekaboo/.cuckoo/conf/
cp ${datadir}/virtualbox.conf /var/lib/peekaboo/.cuckoo/conf/
cp ${datadir}/reporting.conf /var/lib/peekaboo/.cuckoo/conf/



# install amavis
apt-get install -y amavisd-new && true
apt-get install -y arj bzip2 cabextract cpio file gzip lhasa nomarch pax rar unrar unzip zip zoo || true

# get current version and patch
cd /opt/peekaboo/amavis
if [ -f ${datadir}/amavisd-new-2.11.0.tar.xz ]
then
  cp ${datadir}/amavisd-new-2.11.0.tar.xz .
else
  curl https://www.ijs.si/software/amavisd/amavisd-new-2.11.0.tar.xz -o amavisd-new-2.11.0.tar.xz
fi
tar xvf amavisd-new-2.11.0.tar.xz  amavisd-new-2.11.0/amavisd.conf-default
tar xvf amavisd-new-2.11.0.tar.xz  amavisd-new-2.11.0/amavisd
cd amavisd-new-2.11.0/
patch -p4 < ../peekaboo-amavisd.patch 
patch -p1 < ../debian-find_config_files.patch
mv amavisd /usr/sbin/amavisd-new

# copy amavis config
cp ${datadir}/15-av_scanners /etc/amavis/conf.d/
cp ${datadir}/15-content_filter_mode /etc/amavis/conf.d/
cp ${datadir}/50-user /etc/amavis/conf.d/

systemctl restart amavis


gpasswd -a amavis peekaboo
gpasswd -a peekaboo amavis



# install mysql database
apt-get install -y mariadb-server python-mysqldb
mysql < ${datadir}/mysql.txt || echo "Couldn't create dabases and users. Probably already exists"



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


