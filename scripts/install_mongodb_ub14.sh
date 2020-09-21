#!/bin/bash

# Installing MongoDB 3.6 for Ubuntu 14.04 LTS. Updated due to MongoDB dropping Ubuntu 14.04 LTS from the main repo, MongoDB 3.4 going EOL in Jan 2020, and moving to only 64-bit support.

set -e
set -x

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.6 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list
apt-get update
apt-get install -y mongodb-org
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
service mongod restart
