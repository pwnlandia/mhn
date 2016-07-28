#!/bin/bash

set -e
set -x

if [ -f /etc/debian_version ]; then
    vers=$(grep -P '\d\.\d' /etc/debian_version | cut -c1 )
    if [ ${vers} ]; then
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
    else
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
    fi

    if [ x${vers} == x'8' ]; then
        echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.2 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
    elif [ x${vers} == x'7' ]; then
        echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/3.2 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
    else
        echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list
    fi
    apt-get update
    apt-get install -y mongodb-org

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
