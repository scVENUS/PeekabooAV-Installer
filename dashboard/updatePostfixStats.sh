#!/bin/bash
#
#
#   Update Postfix related stats on the smashing dashboard
#       Currently, it updates the following:
#               * Table for mails currently in mail quueue, because currently scanned by PeekakooAV for example
#   by Marcel Caspar
#  m.caspar@live.de
#
# 17.10.2019
#
# Copyright (C) 2019 Sittig Technologies GmbH
#
#

DASHBOARD_URL="http://peekaboo.company.local:3030"

DATA=$(/usr/bin/python mailq.py);

string='{ "auth_token":"YOUR_AUTH_TOKEN", '${DATA}'}';

$string = \'$string\';

/usr/bin/curl -d "$string" $DASHBOARD_URL/widgets/my-table