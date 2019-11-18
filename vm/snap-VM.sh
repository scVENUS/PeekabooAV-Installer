#!/bin/bash

namePrefix=cuckoo2
ipnet=192.168.56.2
count=10
VBOXMANAGE="/usr/bin/vboxmanage"

function usage() {
    echo $0 "[start|test|snap|stop|harden]"
    echo
    echo "Starts vms"
    echo "Tests connection to Cuckoo Agent (tcp:8000)"
    echo "Snapshots vms"
    echo "Stops vms"
    echo "Harden turns off clipboard and draganddrop"
}

function start(){
    for i in $(seq -w 1 $count)
    do
        $VBOXMANAGE startvm ${namePrefix}${i} --type headless
        sleep 2
    done
}

function stop(){
    for i in $(seq -w 1 $count)
    do
        $VBOXMANAGE controlvm ${namePrefix}${i} acpipowerbutton
        sleep 2
    done
}

function test(){
    for i in $(seq -w 1 $count)
    do
        nc -vz ${ipnet}${i} 8000
    done
}

function snap() {
    for i in $(seq -w 1 $count)
    do
        $VBOXMANAGE snapshot ${namePrefix}${i} take snap1
        sleep 1
        $VBOXMANAGE controlvm ${namePrefix}${i} poweroff
        sleep 1
        $VBOXMANAGE snapshot ${namePrefix}${i} restorecurrent
        sleep 1
    done
}

function harden() {
    for i in $(seq -w 1 $count)
    do
        #$VBOXMANAGE modifyvm ${namePrefix}${i} --groups "/Productive-$d"
        #$VBOXMANAGE modifyvm ${namePrefix}${i} --nic1 hostonly
        #$VBOXMANAGE modifyvm ${namePrefix}${i} --hostonlyadapter1 vboxnet0
        $VBOXMANAGE modifyvm ${namePrefix}${i} --clipboard disabled
        $VBOXMANAGE modifyvm ${namePrefix}${i} --draganddrop disabled
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
"stop" )
    stop
    ;;
"test" )
    test
    ;;
"snap" )
    snap
    ;;
* )
    usage
    ;;
esac
