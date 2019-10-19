#!/bin/bash

echo "We are now adding the user 'peekaboo-dashboard' to the system. Please provide a propper password when asked"
adduser peekaboo-dashboard

cp updatePeekabooStats.sh /home/peekaboo-dashboard
cp updatePostfixStats.sh /home/peekaboo-dashboard

git clone https://github.com/Clevero/peekabooav-dashboard /home/peekaboo-dashboard/peekabooav-dashboard
chown peekaboo-dashboard:peekaboo-dashboard /home/peekaboo-dashboard/peekabooav-dashboard/ -R
cd /home/peekaboo-dashboard/peekabooav-dashboard/ && bundle install

echo "Installing gem..."
apt install rubygems build-essential

echo "Installing smashing via gem"
gem install smashing

su peekaboo-dashboard
cd /home/peekaboo-dashboard
