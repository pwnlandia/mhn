#!/bin/bash

sudo apt-get -y update
sudo apt-get install -y squid3

cat > /etc/squid3/squid.conf.allow_all <<EOF
acl SSL_ports port 443
acl Safe_ports port 80 # http
acl Safe_ports port 21 # ftp
acl Safe_ports port 443 # https
acl Safe_ports port 70 # gopher
acl Safe_ports port 210 # wais
acl Safe_ports port 1025-65535 # unregistered ports
acl Safe_ports port 280 # http-mgmt
acl Safe_ports port 488 # gss-http
acl Safe_ports port 591 # filemaker
acl Safe_ports port 777 # multiling http
acl CONNECT method CONNECT

acl localnet src 10.0.0.0/8     # RFC1918 possible internal network
acl localnet src 172.16.0.0/12  # RFC1918 possible internal network
acl localnet src 192.168.0.0/16 # RFC1918 possible internal network
acl localnet src fc00::/7       # RFC 4193 local private network range
acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines
http_access allow localnet    
visible_hostname localhost

http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
http_access allow localhost
http_access deny all
http_port 3128
coredump_dir /var/spool/squid3
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern (Release|Packages(.gz)*)$      0       20%     2880
refresh_pattern . 0 20% 4320

EOF

cat > /etc/squid3/squid.conf.deny_all <<EOF
acl SSL_ports port 443
acl Safe_ports port 80 # http
acl Safe_ports port 21 # ftp
acl Safe_ports port 443 # https
acl Safe_ports port 70 # gopher
acl Safe_ports port 210 # wais
acl Safe_ports port 1025-65535 # unregistered ports
acl Safe_ports port 280 # http-mgmt
acl Safe_ports port 488 # gss-http
acl Safe_ports port 591 # filemaker
acl Safe_ports port 777 # multiling http
acl CONNECT method CONNECT

# acl localnet src 10.0.0.0/8     # RFC1918 possible internal network
# acl localnet src 172.16.0.0/12  # RFC1918 possible internal network
# acl localnet src 192.168.0.0/16 # RFC1918 possible internal network
# acl localnet src fc00::/7       # RFC 4193 local private network range
# acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines
# http_access allow localnet    
visible_hostname localhost

http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
http_access allow localhost
http_access deny all
http_port 3128
coredump_dir /var/spool/squid3
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern (Release|Packages(.gz)*)$      0       20%     2880
refresh_pattern . 0 20% 4320

EOF

cd /etc/squid3
mv squid.conf squid.conf.orig
ln -s squid.conf.allow_all squid.conf

sudo service squid3 restart
# default port 3128
