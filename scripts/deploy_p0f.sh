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

apt-get update
apt-get -y install git python-pip supervisor libpcap-dev libjansson-dev python-dev
pip install virtualenv

# install p0f
cd /opt
git clone https://github.com/threatstream/p0f.git
cd p0f
git checkout hpfeeds-publishing
./build.sh
useradd -d /var/empty/p0f -M -r -s /bin/nologin p0f-user
mkdir -p -m 755 /var/empty/p0f

cd hpfeeds
virtualenv env
. env/bin/activate

pip install -e git+https://github.com/threatstream/hpfeeds.git#egg=hpfeeds-dev
pip install ujson
pip install cachetools

cat > p0f_hpfeeds.json <<EOF
{
	"HOST":   "$HPF_HOST",
	"PORT":   $HPF_PORT,
	"IDENT":  "$HPF_IDENT",
	"SECRET": "$HPF_SECRET",
    "PUB_CHANNEL": "p0f.events"
}
EOF

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
EOF

supervisorctl update

cat > /etc/logrotate.d/p0f <<EOF
/var/log/p0f.json.log {
        daily
        copy
        rotate 5
        compress
        delaycompress
        notifempty
        create 700 root root
        sharedscripts
        compresscmd /bin/bzip2
        compressext .bz2
        postrotate
                /usr/bin/supervisorctl restart p0f
        endscript
}
EOF
