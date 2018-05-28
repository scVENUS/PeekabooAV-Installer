#!/bin/bash
set -x

for i in {2..9}; do

    vboxmanage clonevm cuckoo101 --name cuckoo10${i} --snapshot CM  --options link --options keepallmacs --register
    vboxmanage modifyvm cuckoo10${i} --macaddress1 080027E02E4${i}

done

for i in {0..9}; do

    vboxmanage clonevm cuckoo101 --name cuckoo11${i} --snapshot CM  --options link --options keepallmacs --register
    vboxmanage modifyvm cuckoo11${i} --macaddress1 080027E02E5${i}

done


for i in {0..9}; do

    vboxmanage clonevm cuckoo101 --name cuckoo12${i} --snapshot CM  --options link --options keepallmacs --register
    vboxmanage modifyvm cuckoo12${i} --macaddress1 080027E02E6${i}

done

for i in {0..9}; do

    vboxmanage clonevm cuckoo101 --name cuckoo13${i} --snapshot CM  --options link --options keepallmacs --register
    vboxmanage modifyvm cuckoo13${i} --macaddress1 080027E02E7${i}

done
