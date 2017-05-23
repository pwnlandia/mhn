#!/bin/bash
#
# NOTE: This script was tested and is working under Amazon Linux AMI 2016.09
#       More fix will be applied soon in able to get this to work with RHEL/CentOS 6.x based OSes
#

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

# This will export the HPF_* variables
. ./registration.sh $server_url $deploy_key "snort"

# Install required packages
yum -y install epel-release
yum -y groupinstall "Development Tools"
yum -y install libpcap libpcap-devel pcre pcre-devel zlib zlib-devel python-pip libtool git tcpdump flex bison

pip install --upgrade setuptools
pip install --upgrade distribute
pip install virtualenv

# Install hpfeeds and other required libraries
cd /usr/local/src
rm -rf libdnet
git clone https://github.com/dugsong/libdnet
cd libdnet
./configure "CFLAGS=-fPIC" && make && make install
ldconfig

cd /usr/local/src
rm -rf daq*
wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz
tar zxvf daq-2.0.6.tar.gz
cd daq-2.0.6
export PATH=$PATH:/usr/local/bin
./configure && make && sudo make install
ldconfig

cd /tmp
rm -rf libjans*
wget http://www.digip.org/jansson/releases/jansson-2.10.tar.gz
tar zxvf jansson-2.10.tar.gz
cd jansson-2.10
./configure && make && make install

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
ln -s /lib/libhpfeeds.so.1 /usr/local/lib/libhpfeeds.so.1

cd /tmp
rm -rf snort
git clone -b hpfeeds-support https://github.com/threatstream/snort.git
export CPPFLAGS=-I/include
cd snort
./configure --prefix=/opt/snort --with-dnet-includes=/usr/local/src/libdnet/include --with-daq-libraries=/usr/local/src/daq-2.0.6/os-daq-modules && make && make install

mkdir -p /opt/snort/etc /opt/snort/rules /opt/snort/lib/snort_dynamicrules /opt/snort/lib/snort_dynamicpreprocessor /var/log/snort/
cd etc
cp snort.conf classification.config reference.config threshold.conf unicode.map /opt/snort/etc/
touch  /opt/snort/rules/white_list.rules
touch  /opt/snort/rules/black_list.rules

cd /opt/snort/etc/
sed -i 's#/usr/local/#/opt/snort/#' snort.conf

# Disable all the built in rules
sed -i -r 's,include \$RULE_PATH/(.*),# include $RULE_PATH/\1,' snort.conf

# Enable our local rules
sed -i 's,# include $RULE_PATH/local.rules,include $RULE_PATH/local.rules,' snort.conf

# Enable hpfeeds
sed -i "s/# hpfeeds/# hpfeeds\noutput log_hpfeeds: host $HPF_HOST, ident $HPF_IDENT, secret $HPF_SECRET, channel snort.alerts, port $HPF_PORT/" snort.conf


IP=$(ifconfig $INTERFACE | grep 'inet addr' | cut -f2 -d: | awk '{print $1}')
sed -i "s/ipvar HOME_NET any/ipvar HOME_NET $IP/" snort.conf

# Installing snort rules.
# mhn.rules will be used as local.rules.
rm -f /opt/snort/rules/local.rules
ln -s /opt/mhn/rules/mhn.rules /opt/snort/rules/local.rules

# Supervisor will manage snort-hpfeeds
pip install supervisor

# Export supervisor PATH
echo 'pathmunge /usr/local/bin' > /etc/profile.d/supervisor.sh
chmod +x /etc/profile.d/supervisor.sh
. /etc/profile

# Initial config for supervisor
cd /tmp
rm -f supervisord.conf
echo_supervisord_conf > supervisord.conf
sudo cp supervisord.conf /etc/supervisord.conf
sudo mkdir -p /etc/supervisord.d/

# Append snort configuration supervisord.conf
cat >> /etc/supervisord.conf <<EOF
[program:snort]
command=/opt/snort/bin/snort -c /opt/snort/etc/snort.conf -i eth0
directory=/opt/snort
stdout_logfile=/var/log/snort.log
stderr_logfile=/var/log/snort.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT

[include]
files = /etc/supervisord.d/*.conf
EOF

# Download supervisord init script
wget https://gist.githubusercontent.com/joeneldeasis/af8a534322551a031e44c8c9ed9b8905/raw/fe85c7d1d9b6562eacf82a7445733f3bd1ee5444/supervisord -O /etc/rc.d/init.d/supervisord
chmod +x /etc/rc.d/init.d/supervisord
chkconfig --add supervisord
chkconfig supervisord on
service supervisord start

# Add cron to update rules daily
cat > /etc/cron.daily/update_snort_rules.sh <<EOF
#!/bin/bash

mkdir -p /opt/mhn/rules
rm -f /opt/mhn/rules/mhn.rules.tmp

echo "[`date`] Updating snort signatures ..."
wget $server_url/static/mhn.rules -O /opt/mhn/rules/mhn.rules.tmp && \
	mv /opt/mhn/rules/mhn.rules.tmp /opt/mhn/rules/mhn.rules && \
	(/usr/local/bin/supervisorctl update ; /usr/local/bin/supervisorctl restart snort ) && \
	echo "[`date`] Successfully updated snort signatures" && \
	exit 0

echo "[`date`] Failed to update snort signatures"
exit 1
EOF

# Alias for supervisorctl if PATH does not work
echo "alias supervisorctl='/usr/local/bin/supervisorctl'" >> /root/.bashrc

chmod 755 /etc/cron.daily/update_snort_rules.sh
/etc/cron.daily/update_snort_rules.sh

/usr/local/bin/supervisorctl update
