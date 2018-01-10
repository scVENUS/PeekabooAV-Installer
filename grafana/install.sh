#!/usr/bin/env bash

wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_4.6.3_amd64.deb
sudo apt-get install -y adduser libfontconfig
sudo dpkg -i grafana_4.6.3_amd64.deb

sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

grafana-cli plugins install briangann-gauge-panel
grafana-cli plugins install grafana-piechart-panel
service grafana-server restart
