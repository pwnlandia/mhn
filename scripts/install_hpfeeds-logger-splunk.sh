#!/bin/bash

set -e

apt-get update
apt-get install -y git python-pip python-dev
pip install virtualenv

SCRIPTS=`dirname $0`

cd /opt/
git clone https://github.com/threatstream/hpfeeds-logger.git
cd hpfeeds-logger
virtualenv env
. env/bin/activate
pip install -r requirements.txt
chmod 755 -R .

IDENT=hpfeeds-logger-splunk
SECRET=`python -c 'import uuid;print str(uuid.uuid4()).replace("-","")'`
CHANNELS='amun.events,dionaea.connections,dionaea.capture,glastopf.events,beeswarm.hive,kippo.sessions,conpot.events,snort.alerts,wordpot.events,shockpot.events,p0f.events'

cat > /opt/hpfeeds-logger/splunk.json <<EOF
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
        "wordpot.events",
        "shockpot.events",
        "p0f.events"
    ],
    "log_file": "/var/log/mhn-splunk.log",
    "formatter_name": "splunk"
}
EOF

deactivate

. /opt/hpfeeds/env/bin/activate
python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "" "$CHANNELS"

apt-get install -y supervisor

cat >> /etc/supervisor/conf.d/hpfeeds-logger-splunk.conf <<EOF 
[program:hpfeeds-logger-splunk]
command=/opt/hpfeeds-logger/env/bin/python logger.py splunk.json
directory=/opt/hpfeeds-logger
stdout_logfile=/var/log/hpfeeds-logger-splunk.log
stderr_logfile=/var/log/hpfeeds-logger-splunk.err
autostart=true
autorestart=true
startsecs=1
EOF

supervisorctl update
