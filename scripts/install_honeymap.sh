#!/bin/bash

apt-get install -y git golang mercurial make coffeescript
DEBIAN_FRONTEND=noninteractive apt-get install -y golang-go

SECRET=`python -c 'import uuid;print str(uuid.uuid4()).replace("-","")'`
/opt/hpfeeds/env/bin/python /opt/hpfeeds/broker/add_user.py honeymap $SECRET "" "geoloc.events"

cd /opt
git clone https://github.com/threatstream/honeymap.git

cd /opt/honeymap/server
go get
go build
cat > config.json <<EOF
{
   "host": "localhost",
   "port": 10000,
   "ident": "honeymap",
   "auth": "$SECRET"
}
EOF

cd ..
make

apt-get install supervisor

cat >> /etc/supervisor/conf.d/honeymap.conf <<EOF 
[program:honeymap]
command=/opt/honeymap/server/server
directory=/opt/honeymap
stdout_logfile=/var/log/honeymap.log
stderr_logfile=/var/log/honeymap.err
autostart=true
autorestart=true
startsecs=10
EOF

supervisorctl update


apt-get install libgeoip-dev
/opt/hpfeeds/env/bin/pip install GeoIP

cd /opt/
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && gzip -d GeoLiteCity.dat.gz
http://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz && gzip -d GeoLiteCityv6.dat.gz

