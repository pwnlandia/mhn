#!/bin/bash

INTERFACE=eth0

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
. ./registration.sh $server_url $deploy_key "snort"

# 
cron_path="/etc/cron.daily/update_snort_rules.sh"

# linux distro detection module:

if [ -f /etc/lsb-release ]; then linux_version="Ubuntu";
    supervisor_conf_path="/etc/supervisor/conf.d/snort.conf";
elif [ -f /etc/os-release ]; then linux_version="CentOS";
    supervisor_conf_path="/etc/supervisord.d/snort.conf";
<<EOF
elif [ -f /etc/debian-version ]; then linux_version="Debian";
    supervisor_conf_path="";
    cron_path=""
elif [ -f /etc/redhat-release ]; then linux_version="RedHat";
    supervisor_conf_path="";
    cron_path=""
EOF
fi

if [ "$linux_version" == "Ubuntu" ]; then apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential libpcap-dev libjansson-dev libpcre3-dev libdnet-dev libdumbnet-dev libdaq-dev flex bison python-pip git make automake libtool zlib1g-dev supervisor

elif [ "$linux_version" == "CentOS" ]; then yum -y groupinstall 'Development Tools'
yum -y install python-pip zlib-devel libdnet-devel libpcap-devel jansson-devel pcre-devel supervisor
wget https://www.snort.org/downloads/snort/daq-2.0.4.centos7.x86_64.rpm
yum -y localinstall daq-2.0.4.centos7.x86_64.rpm
fi

pip install --upgrade distribute
pip install virtualenv

# Install hpfeeds and required libs...

cd /tmp
rm -rf libev*
wget https://github.com/threatstream/hpfeeds/releases/download/libev-4.15/libev-4.15.tar.gz
tar zxvf libev-4.15.tar.gz 
cd libev-4.15
./configure && make && make install
ldconfig

cd /tmp
rm -rf hpfeeds
git clone https://github.com/threatstream/hpfeeds.git
cd hpfeeds/appsupport/libhpfeeds
autoreconf --install
./configure && make && make install 

cd /tmp
rm -rf snort
git clone -b hpfeeds-support https://github.com/threatstream/snort.git
export CPPFLAGS=-I/include
cd snort
./configure --prefix=/opt/snort && make && make install 

mkdir -p /opt/snort/etc /opt/snort/rules /opt/snort/lib/snort_dynamicrules /opt/snort/lib/snort_dynamicpreprocessor /var/log/snort/
cd etc
cp snort.conf classification.config reference.config threshold.conf unicode.map /opt/snort/etc/
touch  /opt/snort/rules/white_list.rules
touch  /opt/snort/rules/black_list.rules

cd /opt/snort/etc/
# out prefix is /opt/snort not /usr/local...
sed -i 's#/usr/local/#/opt/snort/#' snort.conf 

# disable all the built in rules
sed -i -r 's,include \$RULE_PATH/(.*),# include $RULE_PATH/\1,' snort.conf

# enable our local rules
sed -i 's,# include $RULE_PATH/local.rules,include $RULE_PATH/local.rules,' snort.conf

# enable hpfeeds
sed -i "s/# hpfeeds/# hpfeeds\noutput log_hpfeeds: host $HPF_HOST, ident $HPF_IDENT, secret $HPF_SECRET, channel snort.alerts, port $HPF_PORT/" snort.conf 

if [ "$linux_version" == "Ubuntu" ]; then 
IP=$(ifconfig $INTERFACE | grep 'inet addr' | cut -f2 -d: | awk '{print $1}')
elif [ "$linux_version" == "CentOS" ]; then 
IP=$(ifconfig $INTERFACE | grep 'inet' | cut -f2 -d: | awk '{print $2}')
fi
sed -i "s/ipvar HOME_NET any/ipvar HOME_NET $IP/" snort.conf

# Installing snort rules.
# mhn.rules will be used as local.rules.
rm -f /etc/snort/rules/local.rules
ln -s /opt/mhn/rules/mhn.rules /opt/snort/rules/local.rules

# Config for supervisor separately for different distro:
# supervisord.d
cat > "$supervisor_conf_path" <<EOF
[program:snort]
command=/opt/snort/bin/snort -c /opt/snort/etc/snort.conf -i $INTERFACE
directory=/opt/snort
stdout_logfile=/var/log/snort.log
stderr_logfile=/var/log/snort.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

cat > "$cron_path" <<EOF
#!/bin/bash

mkdir -p /opt/mhn/rules
rm -f /opt/mhn/rules/mhn.rules.tmp

echo "[`date`] Updating snort signatures ..."
wget $server_url/static/mhn.rules -O /opt/mhn/rules/mhn.rules.tmp && \
	mv /opt/mhn/rules/mhn.rules.tmp /opt/mhn/rules/mhn.rules && \
	(supervisorctl update ; supervisorctl restart snort ) && \
	echo "[`date`] Successfully updated snort signatures" && \
	exit 0

echo "[`date`] Failed to update snort signatures"
exit 1
EOF
chmod 755 /etc/cron.daily/update_snort_rules.sh
/etc/cron.daily/update_snort_rules.sh

supervisorctl update
