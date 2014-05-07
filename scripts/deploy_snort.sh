#!/bin/bash

set -e
set -x

# if [ $# -ne 2 ]
#     then
#         echo "Wrong number of arguments supplied."
#         echo "Usage: sh mhndeploy.sh <server_url> <deploy_key>."
#         exit 1
# fi

# server_url=$1
# deploy_key=$2

# echo 'Downloading latest client version from: '$mhnclient_url
# wget $server_url/static/mhnclient.latest.tar.gz -O mhnclient.tar.gz
# tar -xvf mhnclient.tar.gz

# hostname=$(hostname)

# deploy_cmd="curl -s -X POST -H \"Content-Type: application/json\" -d '{\"name\": \"$hostname\", \"hostname\": \"$hostname\", \"deploy_key\": \"$deploy_key\"}' $server_url/api/sensor/ |  python -c 'import json,sys;obj=json.load(sys.stdin);print obj[\"uuid\"]'"
# uuid=$(eval $deploy_cmd)

# if [ -z "$uuid" ]
#     then
#         echo "Could not create sensor using name \"$hostname\"."
#         exit 1
# fi

# echo "Created sensor: " $uuid

######################################################
# TODO: get these from the registration process...
# hpfeeds info
HPF_HOST="mhn-dev.threatstream.com"
HPF_PORT="10000"
HPF_IDENT="conpot.$uuid"
HPF_SECRET="3w3e45r5r56y78u9i9i0o0l0k9j"
######################################################

apt-get update
apt-get install -y git python-pip python-dev
#apt-get install -y python-software-properties
#add-apt-repository -y ppa:honeynet/nightly
apt-get update

pip install --upgrade distribute
pip install virtualenv

# Installing Snort
DEBIAN_FRONTEND=noninteractive apt-get install -y snort

# Editing configuration for Snort.
# Disabling community-sip rules because of conflict with a rule from
# emerging threats.
sed -i 's,include \$RULE_PATH/community-sip.rules,#include \$RULE_PATH/community-sip.rules,1' /etc/snort/snort.conf

SNORT_HPF_HOME=/opt/snort_hpfeeds
mkdir -p $SNORT_HPF_HOME
cd $SNORT_HPF_HOME
virtualenv env
. env/bin/activate
pip install -e git+https://github.com/threatstream/snort_hpfeeds.git#egg=snort_hpfeeds-dev

cat > snort_hpfeeds.conf <<EOF
{
	"sensor_uuid": "$uuid",
	"host":   "$HPF_HOST",
	"port":   $HPF_PORT,
	"ident":  "$HPF_IDENT",
	"secret": "$HPF_SECRET",
	"alert_file": "/var/log/snort/alerts"
}
EOF

# Creating application folders.
mkdir -p /opt/mhn/rules
cp mhn.rules /opt/mhn/rules

# Installing snort rules.
# mhn.rules will be used as local.rules.
rm -f /etc/snort/rules/local.rules
ln -s /opt/mhn/rules/mhn.rules /etc/snort/rules/local.rules

cat > /etc/cron.daily/update_snort_rules.sh <<EOF
#!/bin/bash

rm -f /opt/mhn/rules/mhn.rules.tmp

echo "[`date`] Updating snort signatures ..."
wget $server_url/static/mhn.rules -O /opt/mhn/rules/mhn.rules.tmp && \
	mv /opt/mhn/rules/mhn.rules.tmp /opt/mhn/rules/mhn.rules && \
	killall -SIGHUP snort && \
	echo "[`date`] Successfully updated snort signatures" && \
	exit 0

echo "[`date`] Failed to update snort signatures"
exit 1
EOF
chmod 755 /etc/cron.daily/update_snort_rules.sh
/etc/cron.daily/update_snort_rules.sh

# Supervisor will manage snort-hpfeeds
apt-get install -y supervisor

# Config for supervisor.
cat > /etc/supervisor/conf.d/snort_hpfeeds.conf <<EOF
[program:snort_hpfeeds]
command=/opt/snort_hpfeeds/env/bin/python /opt/snort_hpfeeds/env/bin/snort_hpfeeds.py /opt/snort_hpfeeds/snort_hpfeeds.conf
directory=/opt/snort_hpfeeds
stdout_logfile=/var/log/snort_hpfeeds.out
stderr_logfile=/var/log/snort_hpfeeds.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

supervisorctl update