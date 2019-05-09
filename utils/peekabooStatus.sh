#!/usr/bin/env bash

BLUE='\033[0;34m'
NC='\033[0m'
function blue(){
echo -e $BLUE$@$NC
}

cat /etc/issue
uname -a
echo

blue "Status of systemd units"
for t in amavis peekaboo cuckoohttpd cuckooapi cuckoosandbox \
	mongodb postfix fetchmail grafana-server prometheus node_exporter
do
  echo -n $t
  systemctl status $t | grep "\($t.service \|Active:\)"
done
echo

blue "Status of uwsgi services"
for s in cuckoo-web cuckoo-api
do
  service uwsgi status $s
done
echo

blue "Cuckoo Version: "
/opt/cuckoo/bin/python -c "import cuckoo; print(cuckoo.__version__)"
blue "PeekabooAV Version: "
/opt/peekaboo/bin/python -c "import peekaboo; print(peekaboo.__version__)"
echo
blue "Peekaboo DB:"
echo "show tables" | mysql peekaboo

echo "select count(*) as Number_of_analyses_run from analysis_jobs_v6;" | mysql peekaboo
echo "select count(*) as Number_of_unique_samples from sample_info_v6;" | mysql peekaboo
echo "select sample_info_v6.result,count(sample_info_v6.result) from analysis_jobs_v6 join sample_info_v6 on sample_id=sample_info_v6.id group by sample_info_v6.result" | mysql peekaboo

echo
unit=$(systemctl status peekaboo | grep "Loaded: " | sed 's/.*(\([^;]*\);.*).*/\1/')
user=$(grep User $unit | sed 's/.*=\(.*\)/\1/')
home=$(grep $user /etc/passwd | cut -d : -f 6)
blue "Malware Reports:"
ls $home/malware_reports | wc -l
du -sh $home/malware_reports

echo
( blue "Mailq"
mailq ) | more

echo
blue "Installed package versions"
dpkg -l ansible postfix mariadb-common mariadb-server amavisd-new mongodb sqlite3 tcpdump

blue "Installed pip packages"
/opt/cuckoo/bin/pip show pip cuckoo
/opt/peekaboo/bin/pip show pip peekabooav


blue "Connect to postfix"
echo HELLO | nc -N 127.0.0.1 25

blue "Connect to amavis"
echo HELLO | nc -N 127.0.0.1 10024

blue "Connect to peekaboo socket"
echo '[]' | nc -NU /var/run/peekaboo/peekaboo.sock
echo
