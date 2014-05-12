#!/bin/bash

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
pip install --process-dependency-links -e git+https://github.com/threatstream/snort_hpfeeds.git#egg=snort_hpfeeds-dev

cat > snort_hpfeeds.conf <<EOF
{
	"sensor_uuid": "$uuid",
	"host":   "$HPF_HOST",
	"port":   $HPF_PORT,
	"ident":  "$HPF_IDENT",
	"secret": "$HPF_SECRET",
	"alert_file": "/var/log/snort/alert"
}
EOF

cat > /etc/cron.daily/update_snort_rules.sh <<EOF
#!/bin/bash

mkdir -p /opt/mhn/rules
rm -f /opt/mhn/rules/mhn.rules.tmp

echo "[`date`] Updating snort signatures ..."
wget $server_url/static/mhn.rules -O /opt/mhn/rules/mhn.rules.tmp && \
	mv /opt/mhn/rules/mhn.rules.tmp /opt/mhn/rules/mhn.rules && \
	/etc/init.d/snort restart && \
	echo "[`date`] Successfully updated snort signatures" && \
	exit 0

echo "[`date`] Failed to update snort signatures"
exit 1
EOF
chmod 755 /etc/cron.daily/update_snort_rules.sh
/etc/cron.daily/update_snort_rules.sh

# Installing snort rules.
# mhn.rules will be used as local.rules.
rm -f /etc/snort/rules/local.rules
ln -s /opt/mhn/rules/mhn.rules /etc/snort/rules/local.rules


# Supervisor will manage snort-hpfeeds
apt-get install -y supervisor

# Config for supervisor.
cat > /etc/supervisor/conf.d/snort_hpfeeds.conf <<EOF
[program:snort_hpfeeds]
command=/opt/snort_hpfeeds/env/bin/python /opt/snort_hpfeeds/env/bin/snort_hpfeeds.py -c /opt/snort_hpfeeds/snort_hpfeeds.conf
directory=/opt/snort_hpfeeds
stdout_logfile=/var/log/snort_hpfeeds.out
stderr_logfile=/var/log/snort_hpfeeds.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

supervisorctl update
