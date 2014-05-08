#!/bin/bash

#TODO: replace this with the registration code

# if [ $# -ne 2 ]
#     then
#         echo "Wrong number of arguments supplied."
#         echo "Usage: sh mhndeploy.sh <server_url> <deploy_key>."
#         exit 1
# fi

# server_url=$1
# deploy_key=$2

# hostname=$(hostname)

# curl -s -X POST -H "Content-Type: application/json" -d "{
# 	\"name\": \"$hostname\", 
# 	\"hostname\": \"$hostname\", 
# 	\"deploy_key\": \"$deploy_key\"
# }" $server_url/api/sensor/ > /tmp/conpot-deploy.json

# uuid=$(python -c 'import json;obj=json.load(file("/tmp/conpot-deploy.json"));print obj["uuid"]')

# if [ -z "$uuid" ]
#     then
#         echo "Could not create sensor using name \"$hostname\"."
#         exit 1
# fi

set -e

# echo "Created sensor: " $uuid

######################################################
# TODO: get these from the registration process...
# hpfeeds info
HPF_HOST="mhn-dev.threatstream.com"
HPF_PORT="10000"
HPF_IDENT="conpot.$uuid"
HPF_SECRET="3w3e45r5r56y78u9i9i0o0l0k9j"
######################################################

apt-get update
apt-get install -y git libsmi2ldbl snmp-mibs-downloader python-pip python-dev libxml2-dev libxslt-dev
pip install --upgrade distribute
pip install virtualenv

CONPOT_HOME=/opt/conpot
mkdir -p $CONPOT_HOME
cd $CONPOT_HOME
virtualenv env
. env/bin/activate
pip install -e git+https://github.com/threatstream/hpfeeds.git#egg=hpfeeds-dev
pip install -e git+https://github.com/glastopf/conpot.git#egg=conpot-dev
pip install -e git+https://github.com/glastopf/modbus-tk.git#egg=modbus-tk==0.4

cat > conpot.cfg <<EOF
[session]
timeout = 30

[sqlite]
enabled = False

[syslog]
enabled = False
device = /dev/log
host = localhost
port = 514
facility = local0
socket = dev        ; udp (sends to host:port), dev (sends to device)

[hpfriends]
enabled = True
host = $HPF_HOST
port = $HPF_PORT
ident = $HPF_IDENT
secret = $HPF_SECRET
channels = ["conpot.events", ]

[taxii]
enabled = False
host = taxiitest.mitre.org
port = 80
inbox_path = /services/inbox/default/
use_https = False
include_contact_info = False
contact_name = ...
contact_email = ...

[fetch_public_ip]
enabled = True
urls = ["http://www.telize.com/ip", "http://queryip.net/ip/", "http://ifconfig.me/ip"]
EOF

# setup supervisor

apt-get install -y supervisor

cat > /etc/supervisor/conf.d/conpot.conf <<EOF
[program:conpot]
command=$CONPOT_HOME/env/bin/conpot -c $CONPOT_HOME/conpot.conf
directory=$CONPOT_HOME
stdout_logfile=/var/log/conpot.out
stderr_logfile=/var/log/conpot.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

supervisorctl update
