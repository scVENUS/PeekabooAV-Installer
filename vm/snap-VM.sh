#!/bin/bash
set -x

namePrefix=cuckoo2

function usage() {
    echo $0 "[start|snap]"
    echo
    echo "Starts vms
}

function start() {
    for i in $(seq -w 1 20)}
    do
        vboxmanage startvm ${namePrefix}${i} --type headless
        sleep 2
    done
}

function snap() {
    for i in {01..39}
    do
        vboxmanage snapshot ${namePrefix}${i} take snap1
        sleep 1
        vboxmanage controlvm ${namePrefix}${i} poweroff
        sleep 1
        vboxmanage snapshot ${namePrefix}${i} restorecurrent
        sleep 1
    done
}

if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]]
then
    usage
    exit
fi

case "$1" in
"start" )
    start
    ;;
"snap" )
    snap
    ;;
* )
    usage
    ;;
esac
