#!/usr/bin/env bash

mkdir -p /etc/supervisor
mkdir -p /etc/supervisor/conf.d
cat >> /etc/supervisord.conf <<EOF
[include]
files = /etc/supervisor/conf.d/*.conf
EOF

/etc/init.d/supervisord restart