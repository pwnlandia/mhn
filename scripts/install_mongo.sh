#!/bin/bash

set -e
set -x

if [ -f /etc/debian_version ]; then
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
    echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list
    apt-get update
    apt-get install -y mongodb-org

elif [ -f /etc/redhat-release ]; then
    OS=RHEL

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
    echo "ERROR: Unknown OS\nExiting!"
    exit -1
fi
