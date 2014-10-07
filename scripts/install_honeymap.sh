#!/bin/bash

apt-get install -y git golang mercurial make coffeescript
DEBIAN_FRONTEND=noninteractive apt-get install -y golang-go

SECRET=`python -c 'import uuid;print str(uuid.uuid4()).replace("-","")'`
/opt/hpfeeds/env/bin/python /opt/hpfeeds/broker/add_user.py honeymap $SECRET "" "geoloc.events"

cd /opt
git clone https://github.com/threatstream/honeymap.git

cd /opt/honeymap/server
export GOPATH=`pwd`
go get
go build
cat > config.json <<EOF
{
   "host": "localhost",
   "port": 10000,
   "ident": "honeymap",
   "auth": "$SECRET",
   "channel": "geoloc.events"
}
EOF

cd ..
make

apt-get install -y supervisor

cat > /etc/supervisor/conf.d/honeymap.conf <<EOF 
[program:honeymap]
command=/opt/honeymap/server/server
directory=/opt/honeymap
stdout_logfile=/var/log/honeymap.log
stderr_logfile=/var/log/honeymap.err
autostart=true
autorestart=true
startsecs=10
EOF

apt-get install -y libgeoip-dev
/opt/hpfeeds/env/bin/pip install GeoIP

cd /opt/
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && gzip -d GeoLiteCity.dat.gz
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz && gzip -d GeoLiteCityv6.dat.gz

SECRET=`python -c 'import uuid;print str(uuid.uuid4()).replace("-","")'`
/opt/hpfeeds/env/bin/python /opt/hpfeeds/broker/add_user.py geoloc $SECRET "geoloc.events" amun.events,dionaea.connections,dionaea.capture,glastopf.events,beeswarm.hive,kippo.sessions,conpot.events,snort.alerts,kippo.alerts

cat > /opt/hpfeeds/geoloc.json <<EOF
{
    "HOST": "localhost",
    "PORT": 10000,
    "IDENT": "geoloc", 
    "SECRET": "$SECRET",
    "CHANNELS": [
        "dionaea.connections",
        "dionaea.capture",
        "glastopf.events",
        "beeswarm.hive",
        "kippo.sessions",
        "conpot.events",
        "snort.alerts",
        "amun.events",
        "wordpot.events",
        "shockpot.events",
        "p0f.events"
    ],
    "GEOLOC_CHAN": "geoloc.events"
}
EOF

cat > /etc/supervisor/conf.d/geoloc.conf <<EOF 
[program:geoloc]
command=/opt/hpfeeds/env/bin/python /opt/hpfeeds/examples/geoloc/geoloc.py /opt/hpfeeds/geoloc.json
directory=/opt/hpfeeds/
stdout_logfile=/var/log/geoloc.log
stderr_logfile=/var/log/geoloc.err
autostart=true
autorestart=true
startsecs=10
EOF

supervisorctl update



