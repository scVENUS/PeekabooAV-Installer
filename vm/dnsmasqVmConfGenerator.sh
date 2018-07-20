#!/bin/bash

# reqiures gnu parallel




## CREATE DNSMASQ dhcp-host SECTION
# list vms
# grep names of cuckoo vms
# get vminfo for those machines
# filter for name and macaddress
# values in quotes only
# combine every second line (name, mac)
# swap fields
# add colons to mac and output in correct format

vboxmanage list vms | grep -o "cuckoo[0-9]*" | parallel vboxmanage showvminfo {} --details --machinereadable | grep "^\(name\|macaddress\)" | grep -o "\".*\"" | paste -d " "  - - | tr -d '"' | awk '{print $2 " " $1}' | sed 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\) /dhcp-host=\1:\2:\3:\4:\5:\6,/'



## CREATE DNSMASQ address SECTION
# list vms
# grep names of cuckoo vms
# get vminfo for those machines
# filter for name
# values without quotes only
# output config line hostname/ip
vboxmanage list vms | grep -o "cuckoo[0-9]*" | parallel vboxmanage showvminfo {} --details --machinereadable | grep "^name" | grep -o "cuckoo[0-9]*" | parallel echo "address=/{}/192.168.56.\$(echo {} | grep -o "[0-9]*")"



## CREATE virtualbox.conf FOR cuckoo
# from dnsmasq.conf
function a() {
  name=$(echo $1 | grep -o "cuckoo[0-9]*")
  ip=$(echo $1 | sed 's-.*/.*/--')
  cat <<EOF
[$name]
label=$name
platform=windows
ip=$ip
resultserver_ip=192.168.56.5

EOF
}
export -f a
grep "^address=" /etc/dnsmasq.conf | parallel a {}


