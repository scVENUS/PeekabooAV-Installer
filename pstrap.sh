#!/usr/bin/env bash
#
#
# PeekabooAV-installer bootstrap
#
# a single file to run the installer
#
#
# pipe to bash or run directly
#
#

cd $(mktemp -d --suffix "-PeekabooAV-Installer")
pwd

git clone -b v2.1 https://github.com/scVENUS/PeekabooAV-Installer
cd PeekabooAV-Installer
./PeekabooAV-install.sh --quiet
