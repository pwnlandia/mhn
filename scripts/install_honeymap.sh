#!/bin/bash

set -x
SCRIPTDIR=`dirname "$(readlink -f "$0")"`
MHN_HOME=$SCRIPTDIR/..

if [ -f /etc/debian_version ]; then
    apt-get update
    apt-get install -y git mercurial make coffeescript libgeoip-dev supervisor

    INSTALLER='apt-get'

elif [ -f /etc/redhat-release ]; then
    OS=RHEL
    export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PATH
    yum update -y
    yum install -y  git mercurial make coffee-script.noarch geoip-devel

    INSTALLER='yum'
    REPOPACKAGES=''

    #use python2.7
    PYTHON=/usr/local/bin/python2.7
    PIP=/usr/local/bin/pip2.7
    VIRTUALENV=/usr/local/bin/virtualenv

    #install supervisor from pip2.7
    $PIP install supervisor

else
    echo -e "ERROR: Unknown OS\nExiting!"
    exit -1
fi

####################################################################
# Install a decent version of golang
if [ "$(uname -m)" == "x86_64" ] ;
then
    GO_PACKAGE="go1.12.1.linux-amd64.tar.gz"
else
    GO_PACKAGE="go1.12.1.linux-386.tar.gz"
fi

cd /usr/local/
wget https://storage.googleapis.com/golang/${GO_PACKAGE}
tar zxf ${GO_PACKAGE} && rm ${GO_PACKAGE}

cd /usr/bin/
for X in /usr/local/go/bin/*; 
do 
    echo $X; 
    ln -s $X; 
done
####################################################################

SECRET=`python -c 'import uuid;print str(uuid.uuid4()).replace("-","")'`
/opt/hpfeeds/env/bin/python /opt/hpfeeds/broker/add_user.py honeymap $SECRET "" "geoloc.events"

cd /opt
git clone https://github.com/pwnlandia/honeymap.git

cd /opt/honeymap/server
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

mkdir -p /var/log/mhn

cat > /etc/supervisor/conf.d/honeymap.conf <<EOF 
[program:honeymap]
command=/opt/honeymap/server/server
directory=/opt/honeymap
stdout_logfile=/var/log/mhn/honeymap.log
stderr_logfile=/var/log/mhn/honeymap.err
autostart=true
autorestart=true
startsecs=10
EOF

/opt/hpfeeds/env/bin/pip install geoip2

cd /opt/
mkdir GeoLite2-City
wget https://github.com/pwnlandia/geolite2/raw/master/GeoLite2-City.tar.gz -O GeoLite2-City.tar.gz 
tar xvf GeoLite2-City.tar.gz -C GeoLite2-City --strip-components 1
mv GeoLite2-City/GeoLite2-City.mmdb ./
mkdir GeoLite2-ASN
wget https://github.com/pwnlandia/geolite2/raw/master/GeoLite2-ASN.tar.gz -O GeoLite2-ASN.tar.gz 
tar xvf GeoLite2-ASN.tar.gz -C GeoLite2-ASN --strip-components 1
mv GeoLite2-ASN/GeoLite2-ASN.mmdb ./
SECRET=`python -c 'import uuid;print str(uuid.uuid4()).replace("-","")'`
/opt/hpfeeds/env/bin/python /opt/hpfeeds/broker/add_user.py geoloc $SECRET "geoloc.events" amun.events,dionaea.connections,dionaea.capture,glastopf.events,beeswarm.hive,kippo.sessions,cowrie.sessions,conpot.events,snort.alerts,kippo.alerts,cowrie.alerts,wordpot.events,shockpot.events,p0f.events,suricata.events,elastichoney.events,drupot.events,agave.events

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
        "cowrie.sessions",
        "conpot.events",
        "snort.alerts",
        "amun.events",
        "wordpot.events",
        "shockpot.events",
        "p0f.events",
        "suricata.events",
        "elastichoney.events",
        "drupot.events",
        "agave.events"
    ],
    "GEOLOC_CHAN": "geoloc.events"
}
EOF

cat > /etc/supervisor/conf.d/geoloc.conf <<EOF 
[program:geoloc]
command=/opt/hpfeeds/env/bin/python /opt/hpfeeds/examples/geoloc/geoloc.py /opt/hpfeeds/geoloc.json
directory=/opt/hpfeeds/
stdout_logfile=/var/log/mhn/geoloc.log
stderr_logfile=/var/log/mhn/geoloc.err
autostart=true
autorestart=true
startsecs=10
EOF

supervisorctl update



