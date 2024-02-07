#!/bin/bash

# Install MongoDB for Debian 10 Buster.

[[ "$( lsb_release -i -s )" != "Debian" ]] && [[ "$( lsb_release -r -s )" != "10" ]] && echo "Not Debian 10 - Exiting" && exit -1

set -e
set -x

# Based on instructions from https://docs.mongodb.com/manual/tutorial/install-mongodb-on-debian/ and the MHN Ubuntu 16.04 LTS install_mongodb_ub16.sh script

PACKAGES="gnupg"
MISSING=$(dpkg --get-selections $PACKAGES 2>&1 | grep -v 'install$' | awk '{ print $6 }')
[[ ! -z "$MISSING" ]] && apt install $MISSING

wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -

echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list

apt update && apt install -y mongodb-org

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf

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

systemctl daemon-reload
systemctl enable --now mongodb
systemctl status mongodb
