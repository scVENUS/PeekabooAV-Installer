#!/bin/bash

function usage() {
  echo $0 "<template VM name>"
  echo
  echo "Clones the template VM (arg 1) 20 times"
}

# if no argument given
if [[ -z "$1" ]]
then
  echo "ERROR: no template given"
  echo
  usage
  exit
fi

# help / usage
if [[ "$1" == "-h" || "$1" == "--help" ]]
then
  usage
  exit
fi


set -x
templateName=$1
namePrefix=cuckoo2

for i in $(seq -w 01 20)
do
    vboxmanage clonevm $templateName --name $namePrefix${i} --snapshot CM --options link --register || break
    #vboxmanage modifyvm $namePrefix${i} --macaddress1 080027E02E${i}
done


echo "done. Now use snap-VM.sh to start all vms and take a running snapshot."
echo "You might want to give it some time (some malware checks uptime to test for sandboxes)."
