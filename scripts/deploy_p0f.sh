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
. ./registration.sh $server_url $deploy_key "p0f"

if [ -f /etc/redhat-release ]; then
    OS=RHEL
    export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PATH
	yum update
	yum -y install git  libpcap-devel gcc jansson-devel jansson curl python
	sudo bash -c "curl https://bootstrap.pypa.io/get-pip.py | python2.7"
    yum -y install python-pip
    pip install supervisor
    mkdir -p /etc/supervisor
    mkdir -p /etc/supervisor/conf.d
else
    apt-get update
    apt-get -y install git supervisor libpcap-dev libjansson-dev gcc
fi


# install p0f
cd /opt
git clone https://github.com/threatstream/p0f.git
cd p0f
git checkout origin/hpfeeds
./build.sh
useradd -d /var/empty/p0f -M -r -s /bin/nologin p0f-user || true
mkdir -p -m 755 /var/empty/p0f

cat > /etc/supervisor/conf.d/p0f.conf <<EOF
[program:p0f]
command=/opt/p0f/p0f_wrapper.sh
directory=/opt/p0f
stdout_logfile=/var/log/p0f.out         
stderr_logfile=/var/log/p0f.err          
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=TERM
environment=HPFEEDS_HOST="$HPF_HOST",HPFEEDS_PORT="$HPF_PORT",HPFEEDS_CHANNEL="p0f.events",HPFEEDS_IDENT="$HPF_IDENT",HPFEEDS_SECRET="$HPF_SECRET"
EOF

supervisorctl update
