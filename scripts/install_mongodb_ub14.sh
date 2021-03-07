#!/bin/bash

# Installing MongoDB for Ubuntu 14.04 LTS.

set -e
set -x

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list
apt-get update
apt-get install -y mongodb-org
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
service mongod restart
