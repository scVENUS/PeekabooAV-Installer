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
for t in amavis peekaboo cuckoohttpd
do
  systemctl status $t | grep "\($t.service \|Active:\)"
done
echo

unit=$(systemctl status peekaboo | grep "Loaded: " | sed 's/.*(\([^;]*\);.*).*/\1/')
blue "Systemd Unit: $unit"
wd=$(grep WorkingDirectory $unit | sed 's/.*=\(.*\)/\1/')
blue "Working Directory: $wd"
echo
blue "Git state:"
(
cd $wd
git status
git log | head -n 5
)
echo
blue "Cuckoo Version: "
python -c "import cuckoo; print cuckoo.__version__"
echo
blue "Peekaboo DB:"
echo "show tables" | mysql peekaboo

# select analyses_time,job_hash,sample_id,sha256sum,analysis_result_v2.name,file_extension,reason from analysis_jobs_v2 join sample_info_v2 on sample_id=sample_info_v2.id join analysis_result_v2 on result_id=analysis_result_v2.id;
echo "select count(*) as Number_of_analysed_samples from analysis_jobs_v2 join sample_info_v2 on sample_id=sample_info_v2.id join analysis_result_v2 on result_id=analysis_result_v2.id;" | mysql peekaboo
echo "select count(*) as Number_of_unique_samples from sample_info_v2;" | mysql peekaboo
echo "select analysis_result_v2.name,count(analysis_result_v2.name) from analysis_jobs_v2 join sample_info_v2 on sample_id=sample_info_v2.id join analysis_result_v2 on result_id=analysis_result_v2.id group by analysis_result_v2.name" | mysql peekaboo

echo
user=$(grep User $unit | sed 's/.*=\(.*\)/\1/')
home=$(grep $user /etc/passwd | cut -d : -f 6)
blue "Malware Reports:"
ls $home/malware_reports | wc -l
du -sh $home/malware_reports

echo
mailq
