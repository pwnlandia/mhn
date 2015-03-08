#!/bin/bash

set -e
set -x

if [ $# -ne 2 ]
    then
        echo "Wrong number of arguments supplied."
        echo "Usage: $0 <server_url> <deploy_key>."
        exit 1
fi

server_url=$1
deploy_key=$2

wget $server_url/static/registration.txt -O registration.sh
chmod 755 registration.sh
# Note: this will export the HPF_* variables
. ./registration.sh $server_url $deploy_key "kippo"

apt-get update
apt-get -y install python-dev openssl python-openssl python-pyasn1 python-twisted git python-pip supervisor authbind


# Change real SSH Port to 2222
sed -i 's/Port 22/Port 2222/g' /etc/ssh/sshd_config
reload ssh

# Create Kippo user
useradd -d /home/kippo -s /bin/bash -m kippo -g users

# Get the Kippo source
cd /opt
git clone https://github.com/threatstream/kippo
cd kippo

# Configure Kippo
mv kippo.cfg.dist kippo.cfg
sed -i 's/ssh_port = 2222/ssh_port = 22/g' kippo.cfg
sed -i 's/hostname = svr03/hostname = db01/g' kippo.cfg
sed -i 's/ssh_version_string = SSH-2.0-OpenSSH_5.1p1 Debian-5/ssh_version_string = SSH-2.0-OpenSSH_5.5p1 Debian-4ubuntu5/g' kippo.cfg

# Fix permissions for kippo
chown -R kippo:users /opt/kippo
touch /etc/authbind/byport/22
chown kippo /etc/authbind/byport/22
chmod 777 /etc/authbind/byport/22

# Setup HPFeeds
cat >> /opt/kippo/kippo.cfg <<EOF

[database_hpfeeds]
server = $HPF_HOST
port = $HPF_PORT
identifier = $HPF_IDENT
secret = $HPF_SECRET
debug = false

EOF

# Setup kippo to start at boot
sed -i 's/twistd -y kippo.tac -l log\/kippo.log --pidfile kippo.pid/su kippo -c "authbind --deep twistd -n -y kippo.tac -l log\/kippo.log --pidfile kippo.pid"/g'  /opt/kippo/start.sh

# Config for supervisor.
cat > /etc/supervisor/conf.d/kippo.conf <<EOF
[program:kippo]
command=su kippo -c "authbind --deep twistd -n -y /opt/kippo/kippo.tac -l /opt/kippo/log/kippo.log --pidfile /opt/kippo/kippo.pid"
directory=/opt/kippo
stdout_logfile=/opt/kippo/log/kippo.out
stderr_logfile=/opt/kippo/log/kippo.err
autostart=true
autorestart=true
redirect_stderr=true
stopasgroup = true
EOF

supervisorctl update
