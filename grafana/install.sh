#!/bin/bash -fue

set -x

# latest from https://grafana.com/grafana/download
version=5.1.3
test -f grafana_${version}_amd64.deb || wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_${version}_amd64.deb
sudo apt-get install -y adduser libfontconfig
sudo dpkg -i grafana_${version}_amd64.deb

sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

grafana-cli plugins install briangann-gauge-panel
grafana-cli plugins install grafana-piechart-panel
service grafana-server restart

echo "


Connect to Grafana on port 3000
login with admin:admin


from there you can install dashboards:
6306	PeekabooAV_v3
6309	PeekabooAV drill down - Detailed Job Info

"
