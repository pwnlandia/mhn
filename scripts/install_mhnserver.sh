#!/bin/bash

set -e

apt-get update
apt-get install -y git build-essential python-pip python-dev redis-server
pip install virtualenv

MHN_HOME=`dirname $0`/..
cd $MHN_HOME
MHN_HOME=`pwd`

virtualenv env
. env/bin/activate
pip install -r server/requirements.txt


apt-get install nginx
cat > /etc/nginx/sites-available/default <<EOF 
server {
    listen       80;
    server_name  _;
    
    location / { 
        try_files \$uri @mhnserver; 
    }
    
    root $MHN_HOME/server;

    location @mhnserver {
      include uwsgi_params;
      uwsgi_pass unix:/tmp/uwsgi.sock;
    }

    location  /static {
      alias $MHN_HOME/server/mhn/static;
    }
}
EOF
ln -fs /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

apt-get install supervisor

cat > /etc/supervisor/conf.d/mhn-uwsgi.conf <<EOF 
[program:mhn-uwsgi]
command=$MHN_HOME/env/bin/uwsgi -s /tmp/uwsgi.sock -w mhn:mhn -H $MHN_HOME/env --chmod-socket=666
directory=$MHN_HOME/server
stdout_logfile=/var/log/uwsgi/mhn.log
stderr_logfile=/var/log/uwsgi/mhn.err
autostart=true
autorestart=true
startsecs=10
EOF

cat > /etc/supervisor/conf.d/mhn-celery-worker.conf <<EOF 
[program:mhn-celery-worker]
command=$MHN_HOME/env/bin/celery worker -A mhn.tasks --loglevel=INFO
directory=$MHN_HOME/server
stdout_logfile=$MHN_HOME/server/worker.log
stderr_logfile=$MHN_HOME/server/worker.err
autostart=true
autorestart=true
startsecs=10
EOF

cat > /etc/supervisor/conf.d/mhn-celery-beat.conf <<EOF 
[program:mhn-celery-beat]
command=$MHN_HOME/env/bin/celery beat -A mhn.tasks --loglevel=INFO
directory=$MHN_HOME/server
stdout_logfile=$MHN_HOME/server/worker.log
stderr_logfile=$MHN_HOME/server/worker.err
autostart=true
autorestart=true
startsecs=10
EOF

mkdir -p /var/log/uwsgi
chown www-data:www-data -R $MHN_HOME/server/*

supervisorctl update
/etc/init.d/nginx restart