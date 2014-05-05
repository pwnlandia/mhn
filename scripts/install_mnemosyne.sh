#!/bin/bash

set -e

apt-get update
apt-get install -y git python-pip python-dev mongodb
pip install virtualenv

cd /opt/
git clone https://github.com/johnnykv/mnemosyne.git
cd mnemosyne
virtualenv env
. env/bin/activate
pip install -r requirements.txt
chmod 755 -R .

