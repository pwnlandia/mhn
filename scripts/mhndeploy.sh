# User input.
read -p "Sensor's UUID: " uuid
read -p "Server's API URL: " api_url

# Add ppa to apt sources (Needed for Dionaea).
sudo apt-get install -y python-software-properties
sudo add-apt-repository ppa:honeynet/nightly
sudo apt-get update

# Installing Snort and Dionaea.
sudo apt-get install -y snort
sudo apt-get install --force-yes dionaea

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
#dionaea -c /etc/dionaea/dionaea.conf -w /var/dionaea -u nobody -g nogroup -D
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
sudo mkdir -p /opt/threatstream/mhn/var/log
sudo mkdir -p /opt/threatstream/mhn/var/run
sudo mkdir -p /opt/threatstream/mhn/bin
sudo mkdir -p /etc/mhnclient

# Installing init.d script for mhn.
cd mhnclient
sudo cp mhnclient-initscript.sh /etc/init.d/mhnclient

# Installing mhnclient daemon.
sudo cp mhnclient.py /opt/threatstream/mhn/bin/mhnclient
sudo cp mhnclient.conf /etc/mhnclient/
sudo chmod +x /opt/threatstream/mhn/bin/mhnclient
sudo update-rc.d mhnclient defaults
sudo update-rc.d mhnclient enable

# Setting mhn:mhn as owner of mhn application folders.
sudo chown mhn:mhn /opt/threatstream/mhn/bin/mhnclient
sudo chown -R mhn:mhn /opt/threatstream/mhn
sudo chown -R mhn:mhn /etc/mhnclient

configfile="/etc/mhnclient/mhnclient.conf"
cmd="sudo sed -i 's/\"sensor_uuid\": \"\"/\"sensor_uuid\": \"$uuid\"/1' $configfile"
cmd2="sudo sed -i 's,\"api_url\": \"\",\"api_url\": \"$api_url\",1' $configfile"
echo $cmd
echo $cmd2
eval $cmd
eval $cmd2

sudo pip install -r requirements.txt
cd ..
rm -rf mhnclient
rm mhndeploy.sh
rm mhndeploy.tar.gz
sudo reboot
