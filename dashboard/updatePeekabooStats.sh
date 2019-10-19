#!/bin/bash
#
#
#   Update PeekabooAV related stats on the smashing dashboard
#	Currently, it updates the following:
#		* Updates the count of known samples that are in the PeekabooAV database (so clean and bad samples)
#		* Updates the count of just bad samples discovered through PeekabooAV (also from the database)
#		* Create a statistic for how often a predefined list of file extensions are scanned by Cuckoo 
#			(currently  jpeg, jpg,  pdf, doc, docx, png, xls, xlsx, exe, zip, bat)
#		* Updates the counts for running analysis VM's and pending and reported Cuckcoo tasks
#   by Marcel Caspar
#  m.caspar@live.de
#
# 17.10.2019
#
# Copyright (C) 2019 Sittig Technologies GmbH
#
#

DASHBOARD_URL="http://peekaboo.company.local:3030"

filesKnown=$(echo "SELECT COUNT(id) FROM sample_info_v6;" | mysql -s peekaboo)

filesBad=$(echo "SELECT COUNT(id) FROM sample_info_v6 WHERE result = 'bad';" | mysql -s peekaboo)

/usr/bin/curl -d '{ "auth_token": "YOUR_AUTH_TOKEN", "count": '$filesKnown' }' \$DASHBOARD_URL/widgets/known
/usr/bin/curl -d '{ "auth_token": "YOUR_AUTH_TOKEN", "count": '$filesBad' }' \$DASHBOARD_URL/widgets/bad

running=$(/usr/bin/curl -s http://localhost:8090/cuckoo/status | jq '.tasks.running')
pending=$(/usr/bin/curl -s http://localhost:8090/cuckoo/status | jq '.tasks.pending')
reported=$(/usr/bin/curl -s http://localhost:8090/cuckoo/status | jq '.tasks.reported')

/usr/bin/curl -d '{ "auth_token": "YOUR_AUTH_TOKEN", "value": "'$running'" }' \$DASHBOARD_URL/widgets/running-vms
/usr/bin/curl -d '{ "auth_token": "YOUR_AUTH_TOKEN", "value": "'$reported'" }' \$DASHBOARD_URL/widgets/reported-tasks
/usr/bin/curl -d '{ "auth_token": "YOUR_AUTH_TOKEN", "value": "'$pending'" }' \$DASHBOARD_URL/widgets/pending-tasks


/usr/bin/curlApi=$(/usr/bin/curl -H "Authorization: Bearer S4MPL3" http://localhost:8090/tasks/list -s)

jpeg=$(echo "$/usr/bin/curlApi" | grep ".jpeg" --ignore-case | wc -l $f | cut -f1 -d' ')
jpg=$(echo "$/usr/bin/curlApi" | grep ".jpg" --ignore-case | wc -l $f | cut -f1 -d' ')
pdf=$(echo "$/usr/bin/curlApi" | grep ".pdf" --ignore-case | wc -l $f | cut -f1 -d' ')
doc=$(echo "$/usr/bin/curlApi" | grep ".doc" --ignore-case | wc -l $f | cut -f1 -d' ')
docx=$(echo "$/usr/bin/curlApi" | grep ".docx" --ignore-case | wc -l $f | cut -f1 -d' ')
png=$(echo "$/usr/bin/curlApi" | grep ".png" --ignore-case | wc -l $f | cut -f1 -d' ')
xls=$(echo "$/usr/bin/curlApi" | grep ".xls" --ignore-case | wc -l $f | cut -f1 -d' ')
xlsx=$(echo "$/usr/bin/curlApi" | grep ".xlsx" --ignore-case | wc -l $f | cut -f1 -d' ')
exe=$(echo "$/usr/bin/curlApi" | grep ".exe" --ignore-case | wc -l $f | cut -f1 -d' ')
zip=$(echo "$/usr/bin/curlApi" | grep ".zip" --ignore-case | wc -l $f | cut -f1 -d' ')
bat=$(echo "$/usr/bin/curlApi" | grep ".bat" --ignore-case | wc -l $f | cut -f1 -d' ')

jpegObject='{"label": ".jpeg", "value": '""$jpeg""'}'
jpgObject='{"label": ".jpg", "value": '""$jpg""'}'
pdfObject='{"label": ".pdf", "value": '""$pdf""'}'
docObject='{"label": ".doc", "value": '""$doc""'}'
docxObject='{"label": ".docx", "value": '""$docx""'}'
pngObject='{"label": ".png", "value": '""$png""'}'
xlsObject='{"label": ".xls", "value": '""$xls""'}'
xlsxObject='{"label": ".xlsx", "value": '""$xlsx""'}'
exeObject='{"label": ".exe", "value": '""$exe""'}'
zipObject='{"label": ".zip", "value": '""$zip""'}'
batObject='{"label": ".bat", "value": '""$bat""'}'

string='{ "auth_token": "YOUR_AUTH_TOKEN", "items": [ '${jpegObject}', '${jpgObject}', '${pdfObject}', '${docObject}', '${docxObject}', '${pngObject}', '${xlsObject}', '${xlsxObject}', '${exeObject}', '${zipObject}', '${batObject}' ] }'

/usr/bin/curl -d "$string" \$DASHBOARD_URL/widgets/filetype-counts