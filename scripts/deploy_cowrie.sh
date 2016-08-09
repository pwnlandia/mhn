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
. ./registration.sh $server_url $deploy_key "cowrie"

apt-get update
apt-get -y install python-twisted python-crypto python-pyasn1 python-gmpy2 python-zope.interface python-dev openssl python-openssl git python-pip supervisor authbind

# Change real SSH Port to 2222
sed -i 's/Port 22$/Port 2222/g' /etc/ssh/sshd_config
service ssh restart

# Create non-root cowrie user
useradd -d /home/cowrie -s /bin/bash -m cowrie -g users

# Get the cowrie source
cd /opt
git clone https://github.com/micheloosterhof/cowrie.git cowrie
cd cowrie

# Cowrie's configuration file

cp cowrie.cfg.dist cowrie.cfg

sed -i 's/hostname = svr04/hostname = server/g' cowrie.cfg

sed -i 's/#listen_port = 2222/listen_port = 22/g' cowrie.cfg

sed -i 's/ssh_version_string = SSH-2.0-OpenSSH_6.0p1 Debian-4+deb7u2/ssh_version_string = SSH-2.0-OpenSSH_6.7p1 Ubuntu-5ubuntu1.3/g' cowrie.cfg

sed -i 's/#\[database_hpfeeds\]/[database_hpfeeds]/g' cowrie.cfg
sed -i "s/#server = hpfeeds.mysite.org/server = $HPF_HOST/g" cowrie.cfg
sed -i "s/#port = 10000/port = $HPF_PORT/g" cowrie.cfg
sed -i "s/#identifier = abc123/identifier = $HPF_IDENT/g" cowrie.cfg
sed -i "s/#secret = secret/secret = $HPF_SECRET/g" cowrie.cfg
sed -i 's/#debug=false/debug=false/' cowrie.cfg

#Fix permissions for cowrie user
chown -R cowrie:users /opt/cowrie/

# authbind to listen as non-root on port 22
touch /etc/authbind/byport/22
chown cowrie /etc/authbind/byport/22
chmod 770 /etc/authbind/byport/22

# Config for supervisor
cat > /etc/supervisor/conf.d/cowrie.conf <<EOF
[program:cowrie]
command=authbind --deep twistd -l log/cowrie.log --umask 0077 --pidfile cowrie.pid --nodaemon cowrie
directory=/opt/cowrie
stdout_logfile=/opt/cowrie/log/cowrie.out
stderr_logfile=/opt/cowrie/log/cowrie.err
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=cowrie
EOF

supervisorctl update
