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

if [ -f /etc/redhat-release ]; then
    OS=RHEL
    export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PATH
	yum groupinstall "Development Tools" -y
	yum -y install python gcc flex bison zlib zlib-devel libpcap libpcap-devel jansson-devel jansson pcre pcre-devel libdnet libdnet-devel tcpdump epel-release nghttp2 libev-devel libev
	yum -y install https://www.snort.org/downloads/snort/daq-2.0.6-1.centos7.x86_64.rpm
    yum -y install https://www.snort.org/downloads/snort/snort-2.9.9.0-1.centos7.x86_64.rpm
else
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor python build-essential libpcap-dev libjansson-dev libpcre3-dev libdnet-dev libdumbnet-dev libdaq-dev flex bison python-pip git make automake libtool zlib1g-dev

fi 
sudo bash -c "curl https://bootstrap.pypa.io/get-pip.py | python2.7"
pip install --upgrade distribute
pip install virtualenv
pip install supervisor
mkdir -p /etc/supervisor
mkdir -p /etc/supervisor/conf.d
echo_supervisord_conf > /etc/supervisord.conf
cat >> /etc/supervisord.conf <<EOF
[include]
files = /etc/supervisor/conf.d/*.conf
EOF
# Install hpfeeds and required libs...

#cd /tmp
#rm -rf libev*
#wget https://github.com/threatstream/hpfeeds/releases/download/libev-4.15/libev-4.15.tar.gz
#tar zxvf libev-4.15.tar.gz 
#cd libev-4.15
#./configure && make && make install
#ldconfig

cd /tmp
rm -rf hpfeeds
git clone https://github.com/threatstream/hpfeeds.git
cd hpfeeds/appsupport/libhpfeeds
autoreconf --install
./configure && make && make install 

#cd /tmp
#rm -rf snort
#git clone -b hpfeeds-support https://github.com/threatstream/snort.git
#export CPPFLAGS=-I/include
#cd snort
#./configure --prefix=/opt/snort && make && make install 

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


IP=$(ifconfig $INTERFACE | grep 'inet addr' | cut -f2 -d: | awk '{print $1}')
sed -i "s/ipvar HOME_NET any/ipvar HOME_NET $IP/" snort.conf

# Installing snort rules.
# mhn.rules will be used as local.rules.
rm -f /etc/snort/rules/local.rules
rm -f /opt/snort/rules/local.rules
ln -s /opt/mhn/rules/mhn.rules /opt/snort/rules/local.rules

# Supervisor will manage snort-hpfeeds
#apt-get install -y supervisor

# Config for supervisor.
cat > /etc/supervisor/conf.d/snort.conf <<EOF
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

cat > /etc/cron.daily/update_snort_rules.sh <<EOF
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
