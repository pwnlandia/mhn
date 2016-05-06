#!/bin/bash

set -e
set -x
SCRIPTDIR=`dirname "$(readlink -f "$0")"`
MHN_HOME=$SCRIPTDIR/..


if [ -f /etc/debian_version ]; then
    OS=Debian  # XXX or Ubuntu??
    INSTALLER='apt-get'
    REPOPACKAGES='git build-essential python-pip python-dev redis-server libgeoip-dev nginx libsqlite3-dev'
    PYTHON=`which python`
    PIP=`which pip`
    $PIP install virtualenv
    VIRTUALENV=`which virtualenv`

elif [ -f /etc/redhat-release ]; then
    OS=RHEL
    export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PATH
    INSTALLER='yum'
    REPOPACKAGES='epel-release git GeoIP-devel wget redis nginx'

    if  [ ! -f /usr/local/bin/python2.7 ]; then
        $SCRIPTDIR/install_python2.7.sh
    fi

    #use python2.7
    PYTHON=/usr/local/bin/python2.7
    PIP=/usr/local/bin/pip2.7
    $PIP install virtualenv
    VIRTUALENV=/usr/local/bin/virtualenv

    #install supervisor from pip2.7
    $PIP install supervisor
    
else
    echo -e "ERROR: Unknown OS\nExiting!"
    exit -1
fi

$INSTALLER update
$INSTALLER -y install $REPOPACKAGES


cd $MHN_HOME
MHN_HOME=`pwd`

$VIRTUALENV  -p $PYTHON env
. env/bin/activate

pip install -r server/requirements.txt
if [ -f /etc/redhat-release ]; then
    pip install pysqlite==2.8.1
fi

echo "DONE installing python virtualenv"

mkdir -p /var/log/mhn &> /dev/null
cd $MHN_HOME/server/

echo "==========================================================="
echo "  MHN Configuration"
echo "==========================================================="

python generateconfig.py

echo -e "\nInitializing database, please be patient. This can take several minutes"
python initdatabase.py
cd $MHN_HOME

mkdir -p /opt/www
mkdir -p /etc/nginx

if [ $OS == "Debian" ]; then
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    NGINXCONFIG=/etc/nginx/sites-available/default
    touch $NGINXCONFIG
    ln -fs /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    NGINXUG='www-data:www-data'
    NGINXUSER='www-data'

elif [ $OS == "RHEL" ]; then
    NGINXCONFIG=/etc/nginx/conf.d/default.conf
    NGINXUG='nginx:nginx'
    NGINXUSER='nginx'
fi

cat > $NGINXCONFIG <<EOF
server {
    listen       80;
    server_name  _;
    
    location / { 
        try_files \$uri @mhnserver; 
    }
    
    root /opt/www;

    location @mhnserver {
      include uwsgi_params;
      uwsgi_pass unix:/tmp/uwsgi.sock;
    }

    location  /static {
      alias $MHN_HOME/server/mhn/static;
    }
}
EOF


cat > /etc/supervisor/conf.d/mhn-uwsgi.conf <<EOF 
[program:mhn-uwsgi]
command=$MHN_HOME/env/bin/uwsgi -s /tmp/uwsgi.sock -w mhn:mhn -H $MHN_HOME/env --chmod-socket=666
directory=$MHN_HOME/server
stdout_logfile=/var/log/mhn/mhn-uwsgi.log
stderr_logfile=/var/log/mhn/mhn-uwsgi.err
autostart=true
autorestart=true
startsecs=10
EOF

cat > /etc/supervisor/conf.d/mhn-celery-worker.conf <<EOF 
[program:mhn-celery-worker]
command=$MHN_HOME/env/bin/celery worker -A mhn.tasks --loglevel=INFO
directory=$MHN_HOME/server
stdout_logfile=/var/log/mhn/mhn-celery-worker.log
stderr_logfile=/var/log/mhn/mhn-celery-worker.err
autostart=true
autorestart=true
startsecs=10
user=$NGINXUSER
EOF

touch /var/log/mhn/mhn-celery-worker.log /var/log/mhn/mhn-celery-worker.err
chown $NGINXUG /var/log/mhn/mhn-celery-worker.*

cat > /etc/supervisor/conf.d/mhn-celery-beat.conf <<EOF 
[program:mhn-celery-beat]
command=$MHN_HOME/env/bin/celery beat -A mhn.tasks --loglevel=INFO
directory=$MHN_HOME/server
stdout_logfile=/var/log/mhn/mhn-celery-beat.log
stderr_logfile=/var/log/mhn/mhn-celery-beat.err
autostart=true
autorestart=true
startsecs=10
EOF

MHN_UUID=`python -c 'import uuid;print str(uuid.uuid4())'`
SECRET=`python -c 'import uuid;print str(uuid.uuid4()).replace("-","")'`
/opt/hpfeeds/env/bin/python /opt/hpfeeds/broker/add_user.py "collector" "$SECRET" "" "geoloc.events"

while true;
do
    echo -n "Would you like to use remote mongodb for collector? (y/n) "
    read MONGO
    if [ "$MONGO" == "y" -o "$MONGO" == "Y" ]
    then
        echo -n "MongoDB Host: "
        read MONGO_HOST
        echo -n "MongoDB Port: "
        read MONGO_PORT
        echo "The collector will use mongodb server $MONGO_HOST:$MONGO_PORT"
        break
    elif [ "$MONGO" == "n" -o "$MONGO" == "N" ]
    then
        MONGO_HOST='localhost'
        MONGO_PORT=27017
        echo "Using default configuration:"
        echo "    MongoDB Host: localhost"
        echo "    MongoDB Port: 27017"
        break
    fi
done

while true;
do
    echo -n "Would you like to use authentication for mongodb? (y/n) "
    read MONGO_AUTH
    if [ "$MONGO_AUTH" == "y" -o "$MONGO_AUTH" == "Y" ]
    then
        MONGO_AUTH='true'
        echo -n "MongoDB user: "
        read MONGO_USER
        echo -n "MongoDB password: "
        read MONGO_PASSWORD
        echo -n "MongoDB authentication mechanism < SCRAM-SHA-1 | MONGODB-CR >:"
        read MONGO_AUTH_MECHANISM
        echo "The mongo will use credentials $MONGO_HOST:$MONGO_PORT and authentication mechanism $MONGO_AUTH_MECHANISM"
        break
    elif [ "$MONGO_AUTH" == "n" -o "$MONGO_AUTH" == "N" ]
    then
        MONGO_AUTH='false'
        MONGO_USER='null'
        MONGO_PASSWORD='null'
        MONGO_AUTH_MECHANISM='null'
        break
    fi
done

cat > $MHN_HOME/server/collector.json <<EOF
{
  "IDENT": "collector",
  "SECRET": "$SECRET",
  "MHN_UUID": "$MHN_UUID",
  "MONGO_HOST": "$MONGO_HOST",
  "MONGO_PORT": $MONGO_PORT,
  "MONGO_AUTH": $MONGO_AUTH,
  "MONGO_USER": "$MONGO_USER",
  "MONGO_PASSWORD": "$MONGO_PASSWORD",
  "MONGO_AUTH_MECHANISM": "$MONGO_AUTH_MECHANISM"
}
EOF

cat > /etc/supervisor/conf.d/mhn-collector.conf <<EOF 
[program:mhn-collector]
command=$MHN_HOME/env/bin/python collector_v2.py collector.json
directory=$MHN_HOME/server
stdout_logfile=/var/log/mhn/mhn-collector.log
stderr_logfile=/var/log/mhn/mhn-collector.err
autostart=true
autorestart=true
startsecs=10
EOF

touch $MHN_HOME/server/mhn.log
chown $NGINXUG -R $MHN_HOME/server/*

supervisorctl update
/etc/init.d/nginx restart
