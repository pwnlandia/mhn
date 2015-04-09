#!/bin/bash

if [ $# -ne 2 ]
    then
        echo "Wrong number of arguments supplied."
        echo "Usage: $0 <server_url> <deploy_key>."
        exit 1
fi

server_url=$1
deploy_key=$2

wget $server_url/static/registration.txt -O registration.sh
chmod 755 registration.sh
# Note: this will export the HPF_* variables
. ./registration.sh $server_url $deploy_key "conpot"


apt-get update
apt-get install -y git libsmi2ldbl snmp-mibs-downloader python-pip python-dev libxml2-dev libxslt-dev libmysqlclient-dev
apt-get install -y zlib1g-dev # needed for Ubuntu 14.04
pip install --upgrade distribute
pip install virtualenv

CONPOT_HOME=/opt/conpot
mkdir -p $CONPOT_HOME
cd $CONPOT_HOME
virtualenv env
. env/bin/activate
pip install -U setuptools
pip install -e git+https://github.com/threatstream/hpfeeds.git#egg=hpfeeds-dev
pip install -e git+https://github.com/glastopf/conpot.git#egg=conpot-dev
pip install -e git+https://github.com/glastopf/modbus-tk.git#egg=modbus-tk==0.4

cat > conpot.cfg <<EOF
[session]
timeout = 30

[sqlite]
enabled = False

[mysql]
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

[change_mac_addr]
enabled = False
iface = eth0
addr = 00:de:ad:be:ef:00
EOF

# setup supervisor

apt-get install -y supervisor

cat > /etc/supervisor/conf.d/conpot.conf <<EOF
[program:conpot]
command=/opt/conpot/env/bin/conpot --template default -c /opt/conpot/conpot.cfg -l /var/log/conpot.log
directory=/opt/conpot
stdout_logfile=/var/log/conpot.out
stderr_logfile=/var/log/conpot.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

supervisorctl update
