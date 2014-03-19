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

hostname=$(hostname -f)

deploy_cmd="curl -s -X POST -H \"Content-Type: application/json\" -d '{\"name\": \"$hostname\", \"hostname\": \"$hostname\", \"deploy_key\": \"$deploy_key\"}' $server_url/api/sensor/ |  python -c 'import json,sys;obj=json.load(sys.stdin);print obj[\"uuid\"]'"
uuid=$(eval $deploy_cmd)

if [ -z "$uuid" ]
    then
        echo "Could not create sensor."
        exit 1
fi

echo "Created sensor: " $uuid

# Add ppa to apt sources (Needed for Dionaea).
sudo apt-get install -y python-software-properties
sudo add-apt-repository -y ppa:honeynet/nightly
sudo apt-get update

# Installing Snort and Dionaea.
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y snort
sudo apt-get install -y dionaea

# Editing configuration for Snort.
sudo sed -i 's,RULE_PATH /etc/snort/rules,RULE_PATH /opt/mhn/rules,1' /etc/snort/snort.conf
sudo sed -i 's,include \$RULE_PATH,#include \$RULE_PATH,g' /etc/snort/snort.conf
sudo sed -i 's,# site specific rules,# site specific rules\ninclude \$RULE_PATH/mhn.rules,1' /etc/snort/snort.conf

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

# Setting mhn:mhn as owner of mhn application folders.
sudo chown mhn:mhn /opt/mhn/bin/mhnclient
sudo chown -R mhn:mhn /opt/mhn
sudo chown -R mhn:mhn /etc/mhnclient

configfile="/etc/mhnclient/mhnclient.conf"
cmd="sudo sed -i 's/\"sensor_uuid\": \"\"/\"sensor_uuid\": \"$uuid\"/1' $configfile"
cmd2="sudo sed -i 's,\"api_url\": \"\",\"api_url\": \"$server_url/api\",1' $configfile"
eval $cmd
eval $cmd2

sudo pip install -r requirements.txt

# Supervisor will manage mhnclient and Dionea processes.
# Resets all previous settings.
sudo apt-get remove -y supervisor
sudo apt-get purge -y supervisor
sudo apt-get install -y supervisor
# Config for supervisor.
mhncmd="/opt/mhn/bin/mhnclient -c /etc/mhnclient/mhnclient.conf -D"
mhndir="/opt/mhn"
mhnlog="/opt/mhn/var/log/error.log"
diocmd="dionaea -c /etc/dionaea/dionaea.conf -w /var/dionaea -u nobody -g nogroup"
diodir="/var/dionaea"
diolog="/var/dionaea/error.log"
superconfig="autostart=true\nautorestart=true\nredirect_stderr=true\nstopsignal=QUIT"
mhnsetup="\n[program:mhnclient]\ncommand=$mhncmd\ndirectory=$mhndir\nstdout_logfile=$mhnlog\n$superconfig\n"
diosetup="\n[program:dionaea]\ncommand=$diocmd\ndirectory=$diodir\nstdout_logfile=$diolog\n$superconfig\n"
sudo echo $mhnsetup >> /etc/supervisor/supervisord.conf
sudo echo $diosetup >> /etc/supervisor/supervisord.conf

# Cleanup
rm deploy.sh
rm mhnclient.tar.gz
rm mhnclient.py
rm mhnclient.conf
rm requirements.txt
rm mhnclient-initscript.sh
rm mhn.rules

sudo reboot
