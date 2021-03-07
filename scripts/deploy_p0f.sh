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

apt update
apt install -y git supervisor libpcap-dev libjansson-dev gcc

# install p0f
cd /opt
git clone https://github.com/threatstream/p0f.git
cd p0f
git checkout origin/hpfeeds
./build.sh
useradd -d /var/empty/p0f -M -r -s /bin/nologin p0f-user || true
mkdir -p -m 755 /var/empty/p0f

# Register the sensor with the MHN server.
wget $server_url/static/registration.txt -O registration.sh
chmod 755 registration.sh
# Note: this will export the HPF_* variables
. ./registration.sh $server_url $deploy_key "p0f"

# Note: This will change the interface and the ip in the p0f config
sed -i "/INTERFACE=/c\INTERFACE=$INTERFACE" /opt/p0f/p0f_wrapper.sh
sed -i "/MY_ADDRESS=/c\MY_ADDRESS=\$(ip -f inet -o addr show \$INTERFACE|head -n 1|cut -d\\\  -f 7 | cut -d/ -f 1)" /opt/p0f/p0f_wrapper.sh


cat > /etc/supervisor/conf.d/p0f.conf <<EOF
[program:p0f]
command=/opt/p0f/p0f_wrapper.sh
directory=/opt/p0f
stdout_logfile=/var/log/p0f.out         
stderr_logfile=/var/log/p0f.err          
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=TERM
environment=HPFEEDS_HOST="$HPF_HOST",HPFEEDS_PORT="$HPF_PORT",HPFEEDS_CHANNEL="p0f.events",HPFEEDS_IDENT="$HPF_IDENT",HPFEEDS_SECRET="$HPF_SECRET"
EOF

supervisorctl update
