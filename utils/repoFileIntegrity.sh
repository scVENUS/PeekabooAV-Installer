#!/usr/bin/env bash
cd $(dirname $(readlink -e "$0"))

# check for changes in local files relative to files in this repository
RED='\033[0;31m'
GREEN='\033[0;32m'
WHITE='\033[1;37m'
NC='\033[0m'

if [[ "$1" == "-h" || "$1" == "--help" ]]
then
  shift
  echo "$0 [-h|--help|-v|--verbose]"
  echo "$0 update  # copies changed files to repository"
  exit 0
fi

VERBOSE=0
if [[ "$1" == "-v" || "$1" == "--verbose" ]]
then
  shift
  VERBOSE=1
fi

while read p
do
  IFS=' ' read -ra p <<< "$p"
  if [ ! -f ${p[1]} ]
  then
    echo -e "${RED}Doesn't exist${NC} ${p[1]}"
  elif cmp -s ${p[0]} ${p[1]}
  then
    echo -e "${GREEN}File OK${NC} ${p[1]}"
  else
    echo -e "${WHITE}Changed${NC} ${p[1]}"
    #echo "  $(cmp ${p[0]} ${p[1]})"
    if [[ "$1" == "update" ]]
    then
      cp -uv ${p[1]} ${p[0]}
    fi
  fi
  if [ $VERBOSE -eq 1 ]
  then
    diff ${p[0]} ${p[1]}
  fi
done <<EOF
../amavis/15-content_filter_mode /etc/amavis/conf.d/15-content_filter_mode
../amavis/50-peekaboo /etc/amavis/conf.d/50-peekaboo
../amavis/15-av_scanners /etc/amavis/conf.d/15-av_scanners
../cuckoo/virtualbox.conf /var/lib/peekaboo/.cuckoo/conf/virtualbox.conf
../cuckoo/cuckoo.conf /var/lib/peekaboo/.cuckoo/conf/cuckoo.conf
../cuckoo/cuckooprocessor.sh /opt/peekaboo/cuckooprocessor.sh
../cuckoo/reporting.conf /var/lib/peekaboo/.cuckoo/conf/reporting.conf
../peekaboo/peekaboo.conf /opt/peekaboo/peekaboo.conf
../postfix/master.cf /etc/postfix/master.cf
../postfix/main.cf /etc/postfix/main.cf
../systemd/mysql-proxy.socket /etc/systemd/system/mysql-proxy.socket
../systemd/cuckoohttpd.service /etc/systemd/system/cuckoohttpd.service
../systemd/peekaboo.service /etc/systemd/system/peekaboo.service
../systemd/mysql-proxy.service /etc/systemd/system/mysql-proxy.service
../ubuntu/interfaces /etc/network/interfaces
../ubuntu/hosts /etc/hosts
../ubuntu/hostname /etc/hostname
../vbox/vboxmanage /usr/local/bin/vboxmanage
../vbox/vboxmanage.conf /var/lib/peekaboo/vboxmanage.conf
EOF
