#!/bin/bash

set -e
set -x


OS=RHEL
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PATH

cat > /etc/yum.repos.d/mongodb.repo <<EOF
[mongodb-org]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.2/x86_64/
gpgcheck=0
enabled=1
EOF

yum-config-manager --add-repo=/etc/yum.repos.d/mongodb.repo
yum -y update
mkdir -p /data
mkdir -p /data/db
yum -y install mongodb-org-server mongodb-org-shell mongodb-org-tools

if [ ! -f /var/run/mongodb/mongod.pid ]; then
    if  grep -q -i "release 6" /etc/redhat-release; then
	/etc/init.d/mongod start
    elif  grep -q -i "release 7" /etc/redhat-release; then
	systemctl restart mongod
    fi	
fi

