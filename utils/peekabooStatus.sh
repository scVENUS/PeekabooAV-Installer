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
/opt/cuckoo/bin/python -c "import cuckoo; print cuckoo.__version__"
blue "PeekabooAV Version: "
/opt/peekaboo/bin/python -c "import peekaboo; print peekaboo.__version__"
echo
blue "Peekaboo DB:"
echo "show tables" | mysql peekaboo

# select analyses_time,job_hash,sample_id,sha256sum,analysis_result_v2.name,file_extension,reason from analysis_jobs_v2 join sample_info_v2 on sample_id=sample_info_v2.id join analysis_result_v2 on result_id=analysis_result_v2.id;
echo "select count(*) as Number_of_analysed_samples from analysis_jobs_v3 join sample_info_v3 on sample_id=sample_info_v3.id join analysis_result_v3 on result_id=analysis_result_v3.id;" | mysql peekaboo
echo "select count(*) as Number_of_unique_samples from sample_info_v3;" | mysql peekaboo
echo "select analysis_result_v3.name,count(analysis_result_v3.name) from analysis_jobs_v3 join sample_info_v3 on sample_id=sample_info_v3.id join analysis_result_v3 on result_id=analysis_result_v3.id group by analysis_result_v3.name" | mysql peekaboo

echo
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
