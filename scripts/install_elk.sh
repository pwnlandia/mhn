#!/bin/bash

set -x
set -e

DIR=`dirname "$0"`
$DIR/install_hpfeeds-logger-json.sh

######
### Install ELK (https://www.elastic.co)
#
# Make sure the system has enought RAM (2GB was not enought for basic stuff) and disk space, otherwise ES can suddently stop.
# Recommended: 4GB RAM, 15 GB Disk.
#
# Known Issue: ES can fail to start after booting, no idea why. Restart the service with sudo systemctl restart elasticsearch.service
#
### ElasticSearch - https://www.elastic.co/guide/en/elasticsearch/reference/7.5/deb.html#deb-repo
#
# Runs on localhost:9200. Config file: /etc/elasticsearch/elasticsearch.yml
# Status: sudo systemctl status elasticsearch.service
# If exposed to the internet (not recommended), make sure to add FW rules to only allow trusted sources
#
### Kibana - https://www.elastic.co/guide/en/kibana/7.5/deb.html#deb-repo
## https://www.elastic.co/guide/en/kibana/current/access.html
## https://www.elastic.co/guide/en/kibana/current/kibana-authentication.html
#
# Runs on localhost:5601. Config file: /etc/kibana/kibana.yml
# Status: sudo systemctl status kibana.service
#
### Logstash - https://www.elastic.co/guide/en/logstash/7.5/installing-logstash.html#_apt
#
# Runs on localhost:9600-9700. Config file /etc/logstash/logstash.yml & /etc/logstash/conf.d/logstash.conf
# Status: sudo systemctl status logstash.service
# List plugins: /usr/share/logstash/bin/logstash-plugin list
#
######

# Install Java (required by ES)
apt update
apt install -y software-properties-common openjdk-8-jdk

# Install ES
apt install -y apt-transport-https
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
apt update
apt install -y elasticsearch
systemctl enable elasticsearch.service
systemctl start elasticsearch.service 

# Install Kibana
apt install -y kibana
systemctl enable kibana.service
systemctl start kibana.service

# Install Logstash
apt install logstash
systemctl enable logstash.service
systemctl start logstash.service

cat > /etc/logstash/conf.d/mhn.conf <<EOF
input {
  file {
    path => "/var/log/mhn/mhn-json.log"
  }
}

filter {
  json {
    source => "message"
  }

  geoip {
    source => "src_ip"
    target => "src_ip_geo"
    database => "/opt/GeoLite2-City.mmdb"
  }

  geoip {
    source => "dest_ip"
    target => "dest_ip_geo"
    database => "/opt/GeoLite2-City.mmdb"
  }
}

output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    index => "mhn-%{+YYYYMMddHH00}"
    template_name => "mhn_event"
    template => "/etc/logstash/conf.d/mhn-template.json"
    template_overwrite => true
    manage_template => true
  }
}
EOF

cat > /etc/logstash/conf.d/mhn-template.json <<EOF
{
  "index_patterns": "mhn-*",
  "settings": {
    "number_of_shards": 5,
    "number_of_replicas": 0,
    "refresh_interval": "30s"
  },
  "mappings": {
    "properties": {
      "src_ip": {
        "type": "keyword"
      },
      "src_port": {
        "type": "keyword"
      },
      "src_ip_geo"  : {
        "type" : "object",
        "dynamic": true,
        "properties": {
          "city_name": { "type": "keyword" },
          "continent_code": { "type": "keyword" },
          "country_code2": { "type": "keyword" },
          "country_code3": { "type": "keyword" },
          "country_name": { "type": "keyword" },
          "ip": { "type": "keyword" },
          "latitude": { "type": "float" },
          "longitude": { "type": "float" },
          "postal_code": { "type": "keyword" },
          "region_code": { "type": "keyword" },
          "region_name": { "type": "keyword" },
          "timezone": { "type": "keyword" },
          "location" : { "type" : "geo_point" }
        }
      },
      "dest_ip": {
        "type": "keyword"
      },
      "dest_port": {
        "type": "keyword"
      },
      "dest_ip_geo": {
        "type": "object",
        "dynamic": true,
        "properties": {
          "city_name": { "type": "keyword" },
          "continent_code": { "type": "keyword" },
          "country_code2": { "type": "keyword" },
          "country_code3": { "type": "keyword" },
          "country_name": { "type": "keyword" },
          "ip": { "type": "keyword" },
          "latitude": { "type": "float" },
          "longitude": { "type": "float" },
          "postal_code": { "type": "keyword" },
          "region_code": { "type": "keyword" },
          "region_name": { "type": "keyword" },
          "timezone": { "type": "keyword" },
          "location" : { "type" : "geo_point" }
        }
      },
      "app": {
        "type": "keyword"
      },
      "command": {
        "type": "text"
      },
      "dionaea_action": {
        "type": "keyword"
      },
      "direction": {
        "type": "keyword"
      },
      "elastichoney_form": {
        "type": "keyword"
      },
      "elastichoney_payload": {
        "type": "keyword"
      },
      "eth_dst": {
        "type": "keyword"
      },
      "eth_src": {
        "type": "keyword"
      },
      "ids_type": {
        "type": "keyword"
      },
      "ip_id": {
        "type": "keyword"
      },
      "ip_len": {
        "type": "keyword"
      },
      "ip_tos": {
        "type": "keyword"
      },
      "ip_ttl": {
        "type": "keyword"
      },
      "md5": {
        "type": "keyword"
      },
      "p0f_app": {
        "type": "keyword"
      },
      "p0f_link": {
        "type": "keyword"
      },
      "p0f_os": {
        "type": "keyword"
      },
      "p0f_uptime": {
        "type": "keyword"
      },
      "protocol": {
        "type": "keyword"
      },
      "request_url": {
        "type": "keyword"
      },
      "sensor": {
        "type": "keyword"
      },
      "severity": {
        "type": "keyword"
      },
      "sha512": {
        "type": "keyword"
      },
      "signature": {
        "type": "keyword"
      },
      "ssh_password": {
        "type": "keyword"
      },
      "ssh_username": {
        "type": "keyword"
      },
      "ssh_version": {
        "type": "keyword"
      },
      "tcp_flags": {
        "type": "keyword"
      },
      "tcp_len": {
        "type": "keyword"
      },
      "transport": {
        "type": "keyword"
      },
      "type": {
        "type": "keyword"
      },
      "udp_len": {
        "type": "keyword"
      },
      "url": {
        "type": "keyword"
      },
      "user_agent": {
        "type": "keyword"
      },
      "vendor_product": {
        "type": "keyword"
      }
    }
  }
}
EOF

echo
echo 'By default, ELK services listen on localhost. This could be troublesome if Kibana needs to be accessed on LAN or remotely.'
echo 'To fix that, the server.host setting can be changed in /etc/kibana/kibana.yml.'
echo 'However, please keep in mind that no authentication will be requested by default.'
echo 'See https://www.elastic.co/guide/en/kibana/current/kibana-authentication.html to configure one.'
echo
