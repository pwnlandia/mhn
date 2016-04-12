#!/bin/bash

set -e
set -x

SCRIPTS=`dirname "$(readlink -f "$0")"`
MHN_HOME=$SCRIPTS/..

if [ -f /etc/debian_version ]; then
    OS=Debian  # XXX or Ubuntu??

    apt-get update
    apt-get install -y git python-pip python-dev supervisor
    pip install virtualenv

    INSTALLER='apt-get'
    REPOPACKAGES=''

    PYTHON=`which python`
    PIP=`which pip`
    $PIP install virtualenv
    VIRTUALENV=`which virtualenv`

elif [ -f /etc/redhat-release ]; then
    OS=RHEL
    export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PATH
    if  [ ! -f /usr/local/bin/python2.7 ]; then
        $SCRIPTDIR/install_python2.7.sh
    fi

    #use python2.7
    PYTHON=/usr/local/bin/python2.7
    PIP=/usr/local/bin/pip2.7
    VIRTUALENV=/usr/local/bin/virtualenv

else
    echo -e "ERROR: Unknown OS\nExiting!"
    exit -1
fi


echo "==========================================================="
echo "  Mnemosyne Configuration"
echo "==========================================================="

while true;
do
    echo -n "Would you like to use remote mongodb for mnemosyne? (y/n) "
    read MONGO
    if [ "$MONGO" == "y" -o "$MONGO" == "Y" ]
    then
        echo -n "MongoDB Host: "
        read MONGO_HOST
        echo -n "MongoDB Port: "
        read MONGO_PORT
        echo "The mnemosyne will use mongodb server $MONGO_HOST:$MONGO_PORT"
        break
    elif [ "$MONGO" == "n" -o "$MONGO" == "N" ]
    then
        MONGO_HOST='localhost'
        MONGO_PORT=27017
        echo "Using default configuration:"
        echo "    MongoDB Host: localhost"
        echo "    MongoDB Port: 27017"
        bash $SCRIPTS/install_mongo.sh
        break
    fi
done

mkdir -p /opt
cd /opt/
git clone https://github.com/threatstream/mnemosyne.git
cd mnemosyne
$VIRTUALENV -p $PYTHON env
. env/bin/activate
pip install -r requirements.txt
chmod 755 -R .

IDENT=mnemosyne
SECRET=`python -c 'import uuid;print str(uuid.uuid4()).replace("-","")'`
CHANNELS='amun.events,conpot.events,thug.events,beeswarm.hive,dionaea.capture,dionaea.connections,thug.files,beeswarn.feeder,cuckoo.analysis,kippo.sessions,glastopf.events,glastopf.files,mwbinary.dionaea.sensorunique,snort.alerts,wordpot.events,p0f.events,suricata.events,shockpot.events,elastichoney.events'

cat > /opt/mnemosyne/mnemosyne.cfg <<EOF
[webapi]
host = 0.0.0.0
port = 8181

[mongodb]
mongod_host = $MONGO_HOST
mongod_port = $MONGO_PORT
database = mnemosyne

[hpfriends]
host = localhost
port = 10000
ident = $IDENT
secret = $SECRET
channels = $CHANNELS

[file_log]
enabled = True
file = /var/log/mhn/mnemosyne.log

[loggly_log]
enabled = False
token =

[normalizer]
ignore_rfc1918 = False
EOF

deactivate
. /opt/hpfeeds/env/bin/activate
python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "" "$CHANNELS"

mkdir -p /var/log/mhn/

cat >> /etc/supervisor/conf.d/mnemosyne.conf <<EOF 
[program:mnemosyne]
command=/opt/mnemosyne/env/bin/python runner.py --config mnemosyne.cfg
directory=/opt/mnemosyne
stdout_logfile=/var/log/mhn/mnemosyne.out
stderr_logfile=/var/log/mhn/mnemosyne.err
autostart=true
autorestart=true
startsecs=10
EOF

supervisorctl update
