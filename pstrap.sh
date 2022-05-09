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

git clone -b v2.0 https://github.com/scvenus/peekabooav-installer
cd peekabooav-installer
./PeekabooAV-install.sh --quiet
