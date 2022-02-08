#!/bin/bash

set -e
set -x

if [ $# -ne 2 ]
    then
        echo "Wrong number of arguments supplied."
        echo "Usage: $0 <server_url> <deploy_key>."
        exit 1
fi

apt-get update
apt-get install -y python3

server_url=$1
deploy_key=$2

apt-get install -y git python-virtualenv libssl-dev libffi-dev build-essential libpython3-dev python3-minimal authbind python3-venv python3-pip supervisor supervisor
apt-get update

pip3 install --upgrade pip

pip3 install -U supervisor
/etc/init.d/supervisor start || true

useradd -d /home/cowrie -s /bin/bash -m cowrie -g users

cd /opt
git clone https://github.com/micheloosterhof/cowrie.git cowrie
cd cowrie

# Most recent known working version
git checkout 34f8464

# Config for requirements.txt
cat > /opt/cowrie/requirements.txt <<EOF
setuptools==44.0.0
twisted==20.3.0
cryptography==2.8
configparser==4.0.2
pyopenssl==19.1.0
pyparsing==2.4.6
packaging==20.3
appdirs==1.4.3
pyasn1_modules==0.2.8
attrs==19.3.0
service_identity==18.1.0
python-dateutil==2.8.1
tftpy==0.8.0
bcrypt==3.1.7
treq
EOF

#virtualenv cowrie-env #env name has changed to cowrie-env on latest version of cowrie
python3 -m venv cowrie-env
source cowrie-env/bin/activate
# without the following, i get this error:
# Could not find a version that satisfies the requirement csirtgsdk (from -r requirements.txt (line 10)) (from versions: 0.0.0a5, 0.0.0a6, 0.0.0a5.linux-x86_64, 0.0.0a6.linux-x86_64, 0.0.0a3)
pip3 install csirtgsdk==0.0.0a6
pip3 install -r requirements.txt
pip install hpfeeds==3.0.0
pip install hpfeeds3==0.9.10

# Register sensor with MHN server.
wget $server_url/static/registration.txt -O registration.sh
chmod 755 registration.sh
# Note: this will export the HPF_* variables
sudo ./registration.sh $server_url $deploy_key "cowrie"

cd etc
cp cowrie.cfg.dist cowrie.cfg
sed -i 's/hostname = svr04/hostname = server/g' cowrie.cfg
sed -i 's/listen_endpoints = tcp:2222:interface=0.0.0.0/listen_endpoints = tcp:22:interface=0.0.0.0/g' cowrie.cfg
sed -i 's/version = SSH-2.0-OpenSSH_6.0p1 Debian-4+deb7u2/version = SSH-2.0-OpenSSH_6.7p1 Ubuntu-5ubuntu1.3/g' cowrie.cfg
sed -i 's/#\[output_hpfeeds\]/[output_hpfeeds3]/g' cowrie.cfg
sed -i '/\[output_hpfeeds\]/!b;n;cenabled = true' cowrie.cfg
sed -i "s/#server = hpfeeds.mysite.org/server = $HPF_HOST/g" cowrie.cfg
sed -i "s/#port = 10000/port = $HPF_PORT/g" cowrie.cfg
sed -i "s/#identifier = abc123/identifier = $HPF_IDENT/g" cowrie.cfg
sed -i "s/#secret = secret/secret = $HPF_SECRET/g" cowrie.cfg
sed -i 's/#debug=false/debug=false/' cowrie.cfg
cd ..

chown -R cowrie:users /opt/cowrie/
touch /etc/authbind/byport/22
chown cowrie /etc/authbind/byport/22
chmod 770 /etc/authbind/byport/22

# cowrie 34f8464 version error
sed -i 's/output_hpfeeds/output_hpfeeds3/g' /opt/cowrie/src/cowrie/output/hpfeeds3.py

# start.sh is deprecated on new Cowrie version and substituted by "bin/cowrie [start/stop/status]"
sed -i 's/AUTHBIND_ENABLED=no/AUTHBIND_ENABLED=yes/' bin/cowrie
sed -i 's/DAEMONIZE=""/DAEMONIZE="-n"/' bin/cowrie

# Config for supervisor
cat > /etc/supervisor/conf.d/cowrie.conf <<EOF
[program:cowrie]
command=/opt/cowrie/bin/cowrie start
directory=/opt/cowrie
stdout_logfile=/opt/cowrie/var/log/cowrie/cowrie.out
stderr_logfile=/opt/cowrie/var/log/cowrie/cowrie.err
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=cowrie
EOF

supervisorctl update
