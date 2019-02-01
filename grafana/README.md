# Dashboard

This part is not installed automatically, please refer to [install.sh](install.sh)

![Screenshot](Screenshot-2018-1-17%20Grafana%20-%20PeekabooAV.png?raw=true)


## After the installation

Connect to Grafana on port `3000`
and login with `admin:admin`


from there you can add the two data sources (cuckoo and peekaboo) and then install the dashboards:

Both data sources are type MysSQL. You can get the credentials from ```/opt/peekaboo/etc/peekaboo.conf``` and ```/var/lib/peekaboo/.cuckoo/conf/cuckoo.conf``` since the installer generates some random passwords for the db connections.

Lastly import the predefined dashboards with their grafana.com id:

`6306`	PeekabooAV_v3

`6309`	PeekabooAV drill down - Detailed Job Info

[GrafanaLabs Seach](https://grafana.com/dashboards?search=PeekabooAV)
