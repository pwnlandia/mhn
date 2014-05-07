if [ $# -ne 2 ]
    then
        echo "Wrong number of arguments supplied."
        echo "Usage: sh mhndeploy.sh <server_url> <deploy_key>."
        exit 1
fi

server_url=$1
deploy_key=$2

echo 'Downloading latest client version from: '$mhnclient_url
wget $server_url/static/mhnclient.latest.tar.gz -O mhnclient.tar.gz
tar -xvf mhnclient.tar.gz

hostname=$(hostname)

deploy_cmd="curl -s -X POST -H \"Content-Type: application/json\" -d '{\"name\": \"$hostname\", \"hostname\": \"$hostname\", \"deploy_key\": \"$deploy_key\"}' $server_url/api/sensor/ |  python -c 'import json,sys;obj=json.load(sys.stdin);print obj[\"uuid\"]'"
uuid=$(eval $deploy_cmd)

if [ -z "$uuid" ]
    then
        echo "Could not create sensor using name \"$hostname\"."
        exit 1
fi

echo "Created sensor: " $uuid

# Add ppa to apt sources (Needed for Dionaea).
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y python-software-properties
sudo add-apt-repository -y ppa:honeynet/nightly
sudo apt-get update

# Installing Snort and Dionaea.
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y snort
sudo apt-get install -y dionaea

# Editing configuration for Snort.
# Disabling community-sip rules because of conflict with a rule from
# emerging threats.
sudo sed -i 's,include \$RULE_PATH/community-sip.rules,#include \$RULE_PATH/community-sip.rules,1' /etc/snort/snort.conf

wget $server_url/static/mhn.rules -O mhn.rules

# Editing configuration for Dionaea.
sudo mkdir -p /var/dionaea/wwwroot
sudo mkdir -p /var/dionaea/binaries
sudo mkdir -p /var/dionaea/log
sudo chown -R nobody:nogroup /var/dionaea
sudo mv /etc/dionaea/dionaea.conf.dist /etc/dionaea/dionaea.conf
sudo sed -i 's/var\/dionaea\///g' /etc/dionaea/dionaea.conf
sudo sed -i 's/log\//\/var\/dionaea\/log\//g' /etc/dionaea/dionaea.conf
sudo sed -i 's/levels = "all"/levels = "warning,error"/1' /etc/dionaea/dionaea.conf
sudo sed -i 's/mode = "getifaddrs"/mode = "manual"/1' /etc/dionaea/dionaea.conf

# Enables p0f.
#sudo sed -i 's/\/\/\s*"p0f"/"p0f"/g' /etc/dionaea/dionaea.conf

# Preparing Python environment.
sudo apt-get install -y build-essential
sudo apt-get install -y python-dev
sudo apt-get install -y python-setuptools
sudo apt-get install -y libyaml-dev
sudo easy_install pip

# Creating mhn group and user with known gid and uid.
sudo groupadd -g 333 -f mhn
sudo useradd -u 333 -d /home/mhn -g mhn -m mhn

# Creating application folders.
sudo mkdir -p /opt/mhn/var/log
sudo mkdir -p /opt/mhn/var/run
sudo mkdir -p /opt/mhn/bin
sudo mkdir -p /opt/mhn/rules
sudo mkdir -p /etc/mhnclient

# Installing mhnclient daemon.
sudo cp mhn.rules /opt/mhn/rules
sudo cp mhnclient.py /opt/mhn/bin/mhnclient
sudo cp mhnclient.conf /etc/mhnclient/
sudo chmod +x /opt/mhn/bin/mhnclient

# Installing snort rules.
# mhn.rules will be used as local.rules.
sudo rm /etc/snort/rules/local.rules
sudo ln -s /opt/mhn/rules/mhn.rules /etc/snort/rules/local.rules

# Setting mhn:mhn as owner of mhn application folders.
sudo chown -R mhn:mhn /opt/mhn /etc/mhnclient

configfile="/etc/mhnclient/mhnclient.conf"
cmd="sudo sed -i 's/\"sensor_uuid\": \"\"/\"sensor_uuid\": \"$uuid\"/1' $configfile"
cmd2="sudo sed -i 's,\"api_url\": \"\",\"api_url\": \"$server_url/api\",1' $configfile"
eval $cmd
eval $cmd2

sudo pip install -r requirements.txt

# Supervisor will manage mhnclient and Dionea processes.
sudo apt-get install -y supervisor

# Config for supervisor.

cat > /etc/supervisor/conf.d/mhnclient.conf <<EOF
[program:mhnclient]
command=/opt/mhn/bin/mhnclient -c /etc/mhnclient/mhnclient.conf -D
directory=/opt/mhn
stdout_logfile=/opt/mhn/var/log/error.log
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

cat > /etc/supervisor/conf.d/dionaea.conf <<EOF
[program:dionaea]
command=dionaea -c /etc/dionaea/dionaea.conf -w /var/dionaea -u nobody -g nogroup
directory=/var/dionaea
stdout_logfile=/var/dionaea/error.log
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

supervisorctl update

# Cleanup
rm -f deploy.sh mhnclient.tar.gz mhnclient.py mhnclient.conf requirements.txt mhn.rules