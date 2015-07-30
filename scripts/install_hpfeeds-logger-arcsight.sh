#!/bin/bash

set -e
set -x

apt-get update
apt-get install -y git python-pip python-dev libgeoip-dev
pip install virtualenv

SCRIPTS=`dirname $0`

if [ ! -d "/opt/hpfeeds-logger" ]
then
    cd /opt/
    virtualenv hpfeeds-logger
    . hpfeeds-logger/bin/activate
    pip install hpfeeds-logger==0.0.7.0
else
    echo "It looks like hpfeeds-logger is already installed. Moving on to configuration."
fi

IDENT=hpfeeds-logger-arcsight
SECRET=`python -c 'import uuid;print str(uuid.uuid4()).replace("-","")'`
CHANNELS='amun.events,dionaea.connections,dionaea.capture,glastopf.events,beeswarm.hive,kippo.sessions,conpot.events,snort.alerts,suricata.events,wordpot.events,shockpot.events,p0f.events,elastichoney.events'

cat > /opt/hpfeeds-logger/arcsight.json <<EOF
{
    "host": "localhost",
    "port": 10000,
    "ident": "${IDENT}", 
    "secret": "${SECRET}",
    "channels": [
        "amun.events",
        "dionaea.connections",
        "dionaea.capture",
        "glastopf.events",
        "beeswarm.hive",
        "kippo.sessions",
        "conpot.events",
        "snort.alerts",
        "suricata.events",
        "wordpot.events",
        "shockpot.events",
        "p0f.events",
        "elastichoney.events"
    ],
    "log_file": "/var/log/mhn/mhn-arcsight.log",
    "formatter_name": "arcsight"
}
EOF

. /opt/hpfeeds/env/bin/activate
python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "" "$CHANNELS"

mkdir -p /var/log/mhn

apt-get install -y supervisor

cat >> /etc/supervisor/conf.d/hpfeeds-logger-arcsight.conf <<EOF 
[program:hpfeeds-logger-arcsight]
command=/opt/hpfeeds-logger/bin/hpfeeds-logger arcsight.json
directory=/opt/hpfeeds-logger
stdout_logfile=/var/log/mhn/hpfeeds-logger-arcsight.log
stderr_logfile=/var/log/mhn/hpfeeds-logger-arcsight.err
autostart=true
autorestart=true
startsecs=1
EOF

supervisorctl update
