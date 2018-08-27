#!/bin/bash

set -e
set -x

if [ -f /etc/debian_version ]; then

    if [ "$(lsb_release -r -s)" == "16.04" ] || [ "$(lsb_release -r -s)" == "17.04" ]; then

        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
        echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
        apt-get update
        apt-get install -y mongodb-org

        cat > /etc/systemd/system/mongodb.service <<EOF
[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target

[Service]
User=mongodb
ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf

[Install]
WantedBy=multi-user.target
EOF

        systemctl start mongodb
        systemctl status mongodb
        systemctl enable mongodb

    else
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
        echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list
        apt-get update
        apt-get install -y mongodb-org
    fi

elif [ -f /etc/redhat-release ]; then
    OS=RHEL
    export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PATH

cat >> /etc/yum.repos.d/mongodb.repo <<EOF
[mongodb-org]
name=MongoDB Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/
gpgcheck=0
enabled=1
EOF

    yum-config-manager --add-repo=/etc/yum.repos.d/mongodb.repo
    yum -y update
    mkdir -p /data
    mkdir -p /data/db
    yum -y install mongodb-org-server mongodb-org-shell mongodb-org-tools

    if [ ! -f /var/run/mongodb/mongod.pid ]; then
        /etc/init.d/mongod start
    fi

else
    echo -e "ERROR: Unknown OS\nExiting!"
    exit -1
fi
