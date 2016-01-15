#!/bin/bash

set -e
set -x

apt-get update
apt-get install -y libffi-dev build-essential python-pip python-dev git libssl-dev

SCRIPTS=`dirname $0`
bash $SCRIPTS/install_mongo.sh

pip install virtualenv

cd /tmp
wget https://github.com/threatstream/hpfeeds/releases/download/libev-4.15/libev-4.15.tar.gz
tar zxvf libev-4.15.tar.gz 
cd libev-4.15
./configure && make && make install
ldconfig

cd /opt
git clone https://github.com/threatstream/hpfeeds
chmod 755 -R hpfeeds
cd hpfeeds
virtualenv env
. env/bin/activate

pip install cffi
pip install pyopenssl==0.14
pip install pymongo
pip install -e git+https://github.com/rep/evnet.git#egg=evnet-dev
pip install .

mkdir -p /var/log/mhn

apt-get install -y supervisor

echo "==========================================================="
echo "  Hpfeeds Configuration"
echo "==========================================================="

while true;
do
    echo -n "Would you like to use remote mongodb for feedbroker? (y/n) "
    read MONGO
    if [ "$MONGO" == "y" -o "$MONGO" == "Y" ]
    then
        echo -n "MongoDB Host: "
        read MONGO_HOST
        echo -n "MongoDB Port: "
        read MONGO_PORT
        echo "The feedbroker will use mongodb server $MONGO_HOST:$MONGO_PORT"
        sed -i "s/MONGOIP = .*$/MONGOIP = '$MONGO_HOST'/g" /opt/hpfeeds/broker/feedbroker.py
        sed -i "s/MONGOPORT = .*$/MONGOPORT = $MONGO_PORT/g" /opt/hpfeeds/broker/feedbroker.py
        break
    elif [ "$MONGO" == "n" -o "$MONGO" == "N" ]
    then
        echo "Using default configuration:"
        echo "    MongoDB Host: localhost"
        echo "    MongoDB Port: 27017"
        break
    fi
done


cat >> /etc/supervisor/conf.d/hpfeeds-broker.conf <<EOF 
[program:hpfeeds-broker]
command=/opt/hpfeeds/env/bin/python /opt/hpfeeds/broker/feedbroker.py
directory=/opt/hpfeeds
stdout_logfile=/var/log/mhn/hpfeeds-broker.log
stderr_logfile=/var/log/mhn/hpfeeds-broker.err
autostart=true
autorestart=true
startsecs=10
EOF

supervisorctl update
