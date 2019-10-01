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
    service redis start
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
      uwsgi_pass unix:/run/uwsgi.sock;
    }

    location  /static {
      alias $MHN_HOME/server/mhn/static;
    }
}
EOF


cat > /etc/supervisor/conf.d/mhn-uwsgi.conf <<EOF 
[program:mhn-uwsgi]
command=$MHN_HOME/env/bin/uwsgi -s /run/uwsgi.sock -w mhn:mhn -H $MHN_HOME/env --chmod-socket=666 -b 40960
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

cat > $MHN_HOME/server/collector.json <<EOF
{
  "IDENT": "collector",
  "SECRET": "$SECRET",
  "MHN_UUID": "$MHN_UUID"
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

if [ -f /etc/redhat-release ] &&  grep -q -i "release 7" /etc/redhat-release; then
    firewall-cmd --zone=public --add-service=http --permanent
    firewall-cmd --zone=public --add-service=https --permanent
    firewall-cmd --zone=public --add-port=10000/tcp --permanent
    firewall-cmd --reload
    perl -0777pe 's/\s*server {.*}\s*#\s*}//gs' /etc/nginx/nginx.conf > /tmp/nginx.conf
    \mv /tmp/nginx.conf /etc/nginx/nginx.conf
    systemctl enable nginx
    systemctl start nginx
else
    /etc/init.d/nginx restart
fi
