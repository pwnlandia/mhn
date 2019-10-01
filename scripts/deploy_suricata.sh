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
DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential libpcap-dev libjansson-dev libpcre3-dev libdnet-dev libdumbnet-dev libdaq-dev flex bison python-pip git make automake libtool zlib1g-dev python-dev libnetfilter-queue-dev libnetfilter-queue1 libnfnetlink-dev libnfnetlink0 libyaml-dev libmagic-dev autoconf libpcre3 libpcre3-dbg libnet1-dev libyaml-0-2 pkg-config zlib1g libcap-ng-dev libcap-ng0

pip install --upgrade distribute
pip install pyyaml

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
ldconfig

cd /tmp
rm -rf htp*
wget https://github.com/ironbee/libhtp/releases/download/0.5.15/htp-0.5.15.tar.gz
tar -xzvf htp-0.5.15.tar.gz
cd htp-0.5.15
./configure && make && make install
ldconfig

mkdir -p /opt/suricata/etc/suricata/rules /opt/mhn/rules/

cd /tmp
rm -rf suricata
git clone -b hpfeeds-support https://github.com/threatstream/suricata.git
cd suricata
./autogen.sh || ./autogen.sh
export CPPFLAGS=-I/include
./configure --prefix=/opt/suricata --localstatedir=/var/ --enable-non-bundled-htp 
make
make install-full

# Register the sensor with MHN server.
wget $server_url/static/registration.txt -O registration.sh
chmod 755 registration.sh
# Note: this will export the HPF_* variables
. ./registration.sh $server_url $deploy_key "suricata"
 
cd /opt/suricata/etc/suricata
#sed -i -r "/\s*- alert-hpfeeds/,/\s*reconnect: yes # do we reconnect if publish fails/d" suricata.yaml
#sed -i -r "s/^  # hpfeeds output/ # hpfeeds output\n  - alert-hpfeeds:\n      enabled: yes\n      host: $HPF_HOST\n      ident: $HPF_IDENT\n      secret: $HPF_SECRET\n      channel: suricata.events\n      reconnect: yes # do we reconnect if publish fails ?!\n/" suricata.yaml

# replace the faulty magic file
COMMAND="s#magic-file: /usr/share/file/misc/magic#magic-file: /usr/share/file/magic#;"

# delete the example hpfeeds config section
COMMAND+="/  - alert-hpfeeds/,/      reconnect: yes # do we reconnect if publish fails/d;"

# replace the hpfeeds section with the vaues from the env vars
COMMAND+="s/^  # hpfeeds output/"
COMMAND+="  # hpfeeds output\n"
COMMAND+="  - alert-hpfeeds:\n"
COMMAND+="      enabled: yes\n"
COMMAND+="      host: $HPF_HOST\n"
COMMAND+="      port: $HPF_PORT\n"
COMMAND+="      ident: $HPF_IDENT\n"
COMMAND+="      secret: $HPF_SECRET\n"
COMMAND+="      channel: suricata.events\n"
COMMAND+="      reconnect: yes # do we reconnect if publish fails ?!\n/;"

# disable all the rules then enable just the local.rules
COMMAND+="s/^( - .*\.rules)/#\1/;  s/rule-files:/rule-files:\n - local.rules/"

sed -i -r "$COMMAND" suricata.yaml

IP=$(ip -f inet -o addr show $INTERFACE|head -n 1|cut -d\  -f 7 | cut -d/ -f 1)
sed -i "s#    HOME_NET: \"\[192.168.0.0/16,10.0.0.0/8,172.16.0.0/12\]\"#    HOME_NET: \"[$IP]\"#" suricata.yaml

# Installing snort rules.
# mhn.rules will be used as local.rules.
rm -f /opt/suricata/etc/suricata/rules/local.rules
ln -s /opt/mhn/rules/mhn-suricata.rules /opt/suricata/etc/suricata/rules/local.rules

apt-get install -y supervisor

# Config for supervisor.
cat > /etc/supervisor/conf.d/suricata.conf <<EOF
[program:suricata]
command=/opt/suricata/bin/suricata -c /opt/suricata/etc/suricata/suricata.yaml -i $INTERFACE
directory=/opt/suricata
stdout_logfile=/var/log/suricata.log
stderr_logfile=/var/log/suricata.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

cat > /etc/cron.daily/update_suricata_rules.sh <<EOF
#!/bin/bash

mkdir -p /opt/mhn/rules
rm -f /opt/mhn/rules/mhn.rules.tmp

echo "[`date`] Updating suricata signatures ..."
wget $server_url/static/mhn.rules -O /opt/mhn/rules/mhn-suricata.rules.tmp && \
	mv /opt/mhn/rules/mhn-suricata.rules.tmp /opt/mhn/rules/mhn-suricata.rules && \
	(supervisorctl update ; supervisorctl restart suricata ) && \
	echo "[`date`] Successfully updated suricata signatures" && \
	exit 0

echo "[`date`] Failed to update suricata signatures"
exit 1
EOF
chmod 755 /etc/cron.daily/update_suricata_rules.sh
/etc/cron.daily/update_suricata_rules.sh

supervisorctl update
