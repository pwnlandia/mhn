#!/bin/bash

# tested on Digital Ocean: Ubuntu 16.04_x86_64, 14.04_x86_64
# does not work on Ubuntu 12

set -e
set -x

if [ $# -ne 2 ]
    then
        echo "Wrong number of arguments supplied."
        echo "Usage: $0 <server_url> <deploy_key>."
        exit 1
fi

apt-get update
apt-get install -y python

server_url=$1
deploy_key=$2

wget $server_url/static/registration.txt -O registration.sh
chmod 755 registration.sh
# Note: this will export the HPF_* variables
. ./registration.sh $server_url $deploy_key "cowrie"

apt-get update
apt-get -y install python-dev git supervisor authbind openssl python-virtualenv build-essential python-gmpy2 libgmp-dev libmpfr-dev libmpc-dev libssl-dev python-pip libffi-dev

pip install -U supervisor
/etc/init.d/supervisor start || true

sed -i 's/Port 22$/Port 2222/g' /etc/ssh/sshd_config
service ssh restart
useradd -d /home/cowrie -s /bin/bash -m cowrie -g users

cd /opt
git clone https://github.com/micheloosterhof/cowrie.git cowrie
cd cowrie
virtualenv env
source env/bin/activate
# without the following, i get this error:
# Could not find a version that satisfies the requirement csirtgsdk (from -r requirements.txt (line 10)) (from versions: 0.0.0a5, 0.0.0a6, 0.0.0a5.linux-x86_64, 0.0.0a6.linux-x86_64, 0.0.0a3)
pip install csirtgsdk==0.0.0a6
pip install -r requirements.txt 

cp cowrie.cfg.dist cowrie.cfg
sed -i 's/hostname = svr04/hostname = server/g' cowrie.cfg
sed -i 's/#listen_port = 2222/listen_port = 22/g' cowrie.cfg
sed -i 's/ssh_version_string = SSH-2.0-OpenSSH_6.0p1 Debian-4+deb7u2/ssh_version_string = SSH-2.0-OpenSSH_6.7p1 Ubuntu-5ubuntu1.3/g' cowrie.cfg
sed -i 's/#\[output_hpfeeds\]/[output_hpfeeds]/g' cowrie.cfg
sed -i "s/#server = hpfeeds.mysite.org/server = $HPF_HOST/g" cowrie.cfg
sed -i "s/#port = 10000/port = $HPF_PORT/g" cowrie.cfg
sed -i "s/#identifier = abc123/identifier = $HPF_IDENT/g" cowrie.cfg
sed -i "s/#secret = secret/secret = $HPF_SECRET/g" cowrie.cfg
sed -i 's/#debug=false/debug=false/' cowrie.cfg

chown -R cowrie:users /opt/cowrie/
touch /etc/authbind/byport/22
chown cowrie /etc/authbind/byport/22
chmod 770 /etc/authbind/byport/22

sed -i 's/AUTHBIND_ENABLED=no/AUTHBIND_ENABLED=yes/' start.sh
sed -i 's/DAEMONIZE=""/DAEMONIZE="-n"/' start.sh

# Config for supervisor
cat > /etc/supervisor/conf.d/cowrie.conf <<EOF
[program:cowrie]
command=/opt/cowrie/start.sh env
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