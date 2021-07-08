#!/usr/bin/env bash

set -e
set -x
SCRIPTS=`dirname "$(readlink -f "$0")"`
MHN_HOME=$SCRIPTS/..

if [ -f /etc/debian_version ]; then
    OS=Debian  # XXX or Ubuntu??
    apt-get update
    apt-get -y install supervisor

elif [ -f /etc/redhat-release ]; then
    OS=RHEL
    export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PATH
    #install python2.7 if it isn't installed
    if  [ ! -f /usr/local/bin/python2.7 ]; then
        $SCRIPTS/install_python2.7.sh
    fi

    if  [ ! -f /usr/local/bin/pip2.7 ]; then
        $SCRIPTS/install_python2.7.sh
    fi

    #use python2.7/pip2.7
    PYTHON=/usr/local/bin/python2.7
    PIP=/usr/local/bin/pip2.7

    if [ ! -f /usr/local/bin/virtualenv ]; then
        $PIP install virtualenv
        VIRTUALENV=/usr/local/bin/virtualenv
    fi

    if [ -f /usr/local/bin/supervisord ]; then
        echo "Supervisord Already installed. Exiting"
        #exit 0
    fi

    #install supervisor from pip2.7
    mkdir -p /etc/supervisor
    mkdir -p /etc/supervisor/conf.d
    $PIP install supervisor

    echo_supervisord_conf > /etc/supervisord.conf

    cat >> /etc/supervisord.conf <<EOF
[include]
files = /etc/supervisor/conf.d/*.conf
EOF

    if  grep -q -i "release 6" /etc/redhat-release; then
	/usr/local/bin/supervisord -c /etc/supervisord.conf
    elif  grep -q -i "release 7" /etc/redhat-release; then
	cat > /usr/lib/systemd/system/supervisord.service <<EOF
[Unit]
Description=supervisord - Supervisor process control system for UNIX
Documentation=http://supervisord.org
After=network.target

 [Service]
Type=forking
ExecStart=/usr/local/bin/supervisord -c /etc/supervisord.conf
ExecReload=/usr/local/bin/supervisorctl reload
ExecStop=/usr/local/bin/supervisorctl shutdown

[Install]
WantedBy=multi-user.target
EOF
	systemctl daemon-reload
	systemctl enable supervisord
	systemctl start supervisord
    fi	

    supervisorctl update
   
fi
