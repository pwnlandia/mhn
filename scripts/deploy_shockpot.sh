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
. ./registration.sh $server_url $deploy_key "shockpot"

apt-get update
apt-get -y install git python-pip supervisor
pip install virtualenv

# Get the Shockpot source
cd /opt
git clone https://github.com/threatstream/shockpot.git
cd shockpot

virtualenv env
. env/bin/activate
pip install -r requirements.txt

cat > shockpot.conf<<EOF
[server]
host = 0.0.0.0
port = 80

[headers]
server = Apache/2.0.55 (Debian) PHP/5.1.2-1+b1 mod_ssl/2.0.55 OpenSSL/0.9.8b

[hpfeeds]
enabled  = True
host     = $HPF_HOST
port     = $HPF_PORT
identity = $HPF_IDENT
secret   = $HPF_SECRET
channel  = shockpot.events
only_exploits = True

[fetch_public_ip]
enabled = True
urls = ["http://www.telize.com/ip", "http://queryip.net/ip/", "http://ifconfig.me/ip"]

[template]
title = It Works!
EOF

# Config for supervisor.
cat > /etc/supervisor/conf.d/shockpot.conf <<EOF
[program:shockpot]
command=/opt/shockpot/env/bin/python /opt/shockpot/shockpot.py 
directory=/opt/shockpot
stdout_logfile=/opt/shockpot/shockpot.out
stderr_logfile=/opt/shockpot/shockpot.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

supervisorctl update
