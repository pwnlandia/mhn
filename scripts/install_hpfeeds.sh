#!/bin/bash

set -e
set -x

SCRIPTS=`dirname "$(readlink -f "$0")"`
MHN_HOME=$SCRIPTS/..

if [ -f /etc/debian_version ]; then
    apt-get -y update
    # this needs to be installed before calling "which pip", otherwise that command fails
    apt-get -y install libffi-dev build-essential python-pip python-dev git libssl-dev supervisor

    PYTHON=`which python`
    PIP=`which pip`
    $PIP install virtualenv
    VIRTUALENV=`which virtualenv`

elif [ -f /etc/redhat-release ]; then
    export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PATH
    yum install -y yum-utils
    yum-config-manager --add-repo=https://copr.fedoraproject.org/coprs/librehat/shadowsocks/repo/epel-6/librehat-shadowsocks-epel-6.repo
    yum update -y
    yum -y install epel-release libffi-devel libssl-devel shadowsocks-libev-devel

    if  [ ! -f /usr/local/bin/python2.7 ]; then
        $SCRIPTS/install_python2.7.sh
    fi

    #use python2.7
    PYTHON=/usr/local/bin/python2.7
    PIP=/usr/local/bin/pip2.7
    $PIP install virtualenv
    VIRTUALENV=/usr/local/bin/virtualenv

    #install supervisor from pip2.7
    $SCRIPTS/install_supervisord.sh

else
    echo -e "ERROR: Unknown OS\nExiting!"
    exit -1
fi

ldconfig /usr/local/lib/

bash install_mongo.sh

$PIP install virtualenv

cd /tmp
wget https://github.com/Pwnlandia/hpfeeds/releases/download/libev-4.15/libev-4.15.tar.gz
tar zxvf libev-4.15.tar.gz 
cd libev-4.15
./configure && make && make install
ldconfig /usr/local/lib/


mkdir -p /opt
cd /opt
rm -rf /opt/hpfeeds
git clone https://github.com/Pwnlandia/hpfeeds
chmod 755 -R hpfeeds
cd hpfeeds
$VIRTUALENV -p $PYTHON env
. env/bin/activate

pip install cffi
pip install pyopenssl==17.3.0
pip install pymongo
pip install -e git+https://github.com/couozu/pyev.git#egg=pyev
pip install -e git+https://github.com/Pwnlandia/evnet.git#egg=evnet-dev
pip install .
deactivate

mkdir -p /var/log/mhn
mkdir -p /etc/supervisor/
mkdir -p /etc/supervisor/conf.d

cat >> /etc/supervisor/conf.d/hpfeeds-broker.conf <<EOF 
[program:hpfeeds-broker]
command=/opt/hpfeeds/env/bin/python /opt/hpfeeds/broker/feedbroker.py
directory=/opt/hpfeeds
stdout_logfile=/var/log/mhn/hpfeeds-broker.log
stderr_logfile=/var/log/mhn/hpfeeds-broker.err
autostart=true
autorestart=true
startsecs=10
environment=LD_LIBRARY_PATH="/usr/local/lib"
EOF
ldconfig /usr/local/lib/
if [ -f /etc/redhat-release ] &&  grep -q -i "release 7" /etc/redhat-release; then
    systemctl start supervisord || true
else 
    /etc/init.d/supervisor start || true
fi
sleep 5
supervisorctl update
