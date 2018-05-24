#!/bin/bash
set -x


for i in {01..39}; do

    vboxmanage startvm cuckoo1${i} --type headless
    sleep 2

done

sleep 60


for i in {01..39}; do

    vboxmanage snapshot cuckoo1${i} take snap1 
    sleep 1
    vboxmanage controlvm cuckoo1${i}  poweroff
    sleep 1
    vboxmanage snapshot cuckoo1${i} restorecurrent
    sleep 1
    


done
