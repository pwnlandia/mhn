#!/bin/bash

set -e
set -x


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

