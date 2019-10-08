#!/bin/bash

if [ "$1" == "-h" ] ; then
    cat << EOF
confgenerator.sh

Generator for dnsmasq.conf based on virtualbox registered machines and
Cuckoos virtualbox.conf

Configs are only written to stdout.

namePrefix and resultserver_ip env variables are respected.
Default to cuckoo and 192.168.56.5

Have a great day
EOF
    exit 0
fi


# prefix of cuckoo analysis VMs registered in VirtualBox
export namePrefix=${namePrefix:-cuckoo}
export resultserver_ip=${resultserver_ip:-192.168.56.5}


# check if vboxmanage wrapper is in use and call it as user peekaboo
VBOXMANAGE=vboxmanage
function vboxmanagePeekaboo(){
	echo $@
	su peekaboo -c 'vboxmanage "$@"' -- argv0 $@
}

if  [[ $(file $(which vboxmanage)) =~ .*Bourne.* ]]
then
	echo "INFO: vboxmanage wrapper detected. Running vboxmanage as user peekaboo"
	VBOXMANAGE=vboxmanagePeekaboo
	export -f vboxmanagePeekaboo
fi


# tmpFile is later used to create cuckoo virtualbox.conf
tmpFile=$(mktemp)
trap 'rm -f "$tmpFile"; exit $?' INT TERM EXIT KILL

## CREATE DNSMASQ dhcp-host SECTION
echo "########################################################"
echo "##  dnsmasq.conf (based on registered vbox machines)  ##"
echo "########################################################"

# list vms
# grep names of cuckoo vms
# get vminfo for machine
# filter for name and macaddress
# values only
# combine every second line (name, mac)
# reformat and echo
$VBOXMANAGE list vms | \
	grep -o "${namePrefix}[0-9]*" | \
	while read i
	do
		$VBOXMANAGE showvminfo "$i" --details --machinereadable | \
		grep "^\(name\|macaddress\)" | \
		grep -o "\".*\"" | \
		paste -d " "  - - | \
		tr -d '"' | \
		while read n
		do
			name=$(echo "$n" | awk '{print $1}')
			mac=$(echo "$n" | awk '{print $2}')
			num=$(echo "$name" | grep -o "[0-9]*")
			ip="192.168.56.$num"
			echo "$mac $name,$ip" | \
			sed 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\) /dhcp-host=\1:\2:\3:\4:\5:\6,/' >> $tmpFile
		done
	done

echo >> $tmpFile
cat $tmpFile


## CREATE virtualbox.conf FOR cuckoo
# from tmpFile (dnsmasq.conf)
echo
echo "##########################################################################"
echo "## virtualbox.conf (based on created $tmpFile (dnsmasq.conf) ##"
echo "##########################################################################"

function a() {
  name=$(echo $1 | grep -o "${namePrefix}[0-9]*")
  ip=$(echo $1 | grep -o "[0-9\.]\{7,15\}")
  cat <<EOF
[$name]
label=$name
platform=windows
ip=$ip
resultserver_ip=$resultserver_ip

EOF
}
export -f a

grep "^dhcp-host=" $tmpFile | while read i; do a "$i"; done
