#!/bin/bash

set -e
set -x

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
. ./registration.sh $server_url $deploy_key "amun"

apt-get update
apt-get -y install git python-pip supervisor

# Get the Amun source
cd /opt
git clone https://github.com/zeroq/amun.git
cd amun
# Currently only the development branch supports hpfeeds
git checkout development
mkdir hexdumps
AMUN_HOME=/opt/amun 

# Configure Amun (disable vuln-http, too many false alarms here)
sed -i 's/ip: 127.0.0.1/ip: 0.0.0.0/g' conf/amun.conf
sed -i 's/    vuln-http,/#   vuln-http,/g' conf/amun.conf
sed -i $'s/log_modules:/log_modules:\\\n    log-hpfeeds/g' conf/amun.conf

# Modify Ubuntu to accept more open files
echo "104854" > /proc/sys/fs/file-max
ulimit -Hn 104854
ulimit -n 104854

# Setup HPFeeds
cat > /opt/amun/conf/log-hpfeeds.conf <<EOF

[database_hpfeeds]
server = $HPF_HOST
port = $HPF_PORT
identifier = $HPF_IDENT
secret = $HPF_SECRET
debug = 0

EOF


# Config for supervisor.
cat > /etc/supervisor/conf.d/amun.conf <<EOF
[program:amun]
command=$AMUN_HOME/amun_server.py 
directory=/opt/amun
stdout_logfile=/opt/amun/amun.out
stderr_logfile=/opt/amun/amun.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

supervisorctl update
