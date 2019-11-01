#!/bin/bash

INTERFACE=$(basename -a /sys/class/net/e*)


set -e
set -x

if [ $# -ne 2 ]
    then
        if [ $# -eq 3 ]
          then
            INTERFACE=$3
          else
            echo "Wrong number of arguments supplied."
            echo "Usage: $0 <server_url> <deploy_key>."
            exit 1
        fi

fi

compareint=$(echo "$INTERFACE" | wc -w)


if [ "$INTERFACE" = "e*" ] || [ "$compareint" -ne 1 ]
    then
        echo "No Interface selectable, please provide manually."
        echo "Usage: $0 <server_url> <deploy_key> <INTERFACE>"
        exit 1
fi


server_url=$1
deploy_key=$2

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential libpcap-dev libjansson-dev libpcre3-dev libdnet-dev libdumbnet-dev libdaq-dev flex bison python-pip git make automake libtool zlib1g-dev

pip install --upgrade distribute
pip install virtualenv

# Install hpfeeds and required libs...

cd /tmp
rm -rf libev*
wget https://github.com/pwnlandia/hpfeeds/releases/download/libev-4.15/libev-4.15.tar.gz
tar zxvf libev-4.15.tar.gz 
cd libev-4.15
./configure && make && make install
ldconfig

cd /tmp
rm -rf hpfeeds
git clone https://github.com/pwnlandia/hpfeeds.git
cd hpfeeds/appsupport/libhpfeeds
autoreconf --install
./configure && make && make install 

cd /tmp
rm -rf snort
git clone -b hpfeeds-support https://github.com/threatstream/snort.git
export CPPFLAGS=-I/include
cd snort
./configure --prefix=/opt/snort && make && make install 

# Register the sensor with the MHN server.
wget $server_url/static/registration.txt -O registration.sh
chmod 755 registration.sh
# Note: this will export the HPF_* variables
. ./registration.sh $server_url $deploy_key "snort"

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

#Set HOME_NET

IP=$(ip -f inet -o addr show $INTERFACE|head -n 1|cut -d\  -f 7 | cut -d/ -f 1)
sed -i "/ipvar HOME_NET/c\ipvar HOME_NET $IP" /opt/snort/etc/snort.conf

# Installing snort rules.
# mhn.rules will be used as local.rules.
rm -f /etc/snort/rules/local.rules
ln -s /opt/mhn/rules/mhn.rules /opt/snort/rules/local.rules

# Supervisor will manage snort-hpfeeds
apt-get install -y supervisor

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
