#!/bin/bash

# Install MongoDB for Debian 9 Stretch.

set -e
set -x

wget -qO - https://www.mongodb.org/static/pgp/server-4.0.asc | sudo apt-key add -

echo "deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/4.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list

apt-get update
apt-get install -y mongodb-org

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

systemctl start mongodb
systemctl status mongodb
systemctl enable mongodb

