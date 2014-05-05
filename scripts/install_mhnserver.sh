#!/bin/bash

set -e

apt-get update
apt-get install -y git build-essential python-pip python-dev redis-server
pip install virtualenv

MHN_REPO=`dirname $0`/..
cd $MHN_REPO

virtualenv env
. env/bin/activate
pip install -r server/requirements.txt


apt-get install nginx
cat > /etc/nginx/sites-available/default <<EOF 
server {
    listen       80;
    server_name  _;
    
    location / { 
        try_files $uri @mhnserver; 
    }
    
    root /opt/MHN/server;

    location @mhnserver {
      include uwsgi_params;
      uwsgi_pass unix:/tmp/uwsgi.sock;
    }

    location  /static {
      alias /opt/MHN/server/mhn/static;
    }
}
EOF
ln -fs /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
/etc/init.d/nginx restart

apt-get install supervisor

cat >> /etc/supervisor/conf.d/mhn-uwsgi.conf <<EOF 
[program:mhn-uwsgi]
command=/opt/MHN/mhnenv/bin/uwsgi -s /tmp/uwsgi.sock -w mhn:mhn -H /opt/MHN/mhnenv --chmod-socket=666
directory=/opt/MHN/server
stdout_logfile=/var/log/uwsgi/mhn.log
stderr_logfile=/var/log/uwsgi/mhn.err
autostart=true
autorestart=true
startsecs=10
EOF

cat >> /etc/supervisor/conf.d/mhn-celery-worker.conf <<EOF 
[program:mhn-celery-worker]
command=/opt/MHN/mhnenv/bin/celery worker -A mhn.tasks --loglevel=INFO
directory=/opt/MHN/server
stdout_logfile=/opt/MHN/server/worker.log
stderr_logfile=/opt/MHN/server/worker.err
autostart=true
autorestart=true
startsecs=10
EOF

cat >> /etc/supervisor/conf.d/mhn-celery-beat.conf <<EOF 
[program:mhn-celery-beat]
command=/opt/MHN/mhnenv/bin/celery beat -A mhn.tasks --loglevel=INFO
directory=/opt/MHN/server
stdout_logfile=/opt/MHN/server/worker.log
stderr_logfile=/opt/MHN/server/worker.err
autostart=true
autorestart=true
startsecs=10
EOF

mkdir /var/log/uwsgi
chown www-data:www-data -R /opt/MHN/server/*

supervisorctl update