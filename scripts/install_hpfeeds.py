#!/bin/bash

set -e

apt-get update
apt-get install -y libffi-dev build-essential python-pip python-dev mongodb git

pip install virtualenv

cd /tmp
wget http://dist.schmorp.de/libev/libev-4.15.tar.gz
tar zxvf libev-4.15.tar.gz 
cd libev-4.15
./configure && make && make install
ldconfig

cd /opt
git clone https://github.com/threatstream/hpfeeds
chmod 755 -R hpfeeds
cd hpfeeds
virtualenv env
. env/bin/activate

pip install cffi
pip install pyopenssl==0.14
pip install pymongo
pip install -e git+https://github.com/rep/evnet.git#egg=evnet-dev
