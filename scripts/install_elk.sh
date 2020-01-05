#!/bin/bash

set -x
set -e

DIR=`dirname "$0"`
$DIR/install_hpfeeds-logger-json.sh

######
### Install ELK (https://www.elastic.co)
#
# Make sure the system has enought RAM (2GB was not enough for basic stuff), otherwise ES can suddently stop
#
### ElasticSearch - https://www.elastic.co/guide/en/elasticsearch/reference/7.5/deb.html#deb-repo
#
# Runs on localhost:9200. Config file: /etc/elasticsearch/elasticsearch.yml
# Status: systemctl status elasticsearch.service
# If exposed to the internet (not recommended), make sure to add FW rules to only allow trusted sources
#
### Kibana - https://www.elastic.co/guide/en/kibana/7.5/deb.html#deb-repo
#
# Runs on localhost:5601. Config file: /etc/kibana/kibana.yml
# Status: systemctl status kibana.service
#
### Logstash - https://www.elastic.co/guide/en/logstash/7.5/installing-logstash.html#_apt
#
# Runs on localhost:9600-9700. Config file /etc/logstash/logstash.yml & /etc/logstash/conf.d/mhn.conf
# Status: systemctl status logstash.service
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
    start_position => "end"
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
    add_field => [ "[src_ip_geo][coordinates]", "%{[src_ip_geo][longitude]}" ]
    add_field => [ "[src_ip_geo][coordinates]", "%{[src_ip_geo][latitude]}"  ]
  }
  mutate {
    convert => [ "[src_ip_geo][coordinates]", "float"]
  }

  geoip {
    source => "dst_ip"
    target => "dst_ip_geo"
    database => "/opt/GeoLite2-City.mmdb"
    add_field => [ "[dst_ip_geo][coordinates]", "%{[dst_ip_geo][longitude]}" ]
    add_field => [ "[dst_ip_geo][coordinates]", "%{[dst_ip_geo][latitude]}"  ]
  }

  mutate {
    convert => [ "[dst_ip_geo][coordinates]", "float"]
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
      "app": {
        "type": "keyword"
      },
      "command": {
        "type": "text"
      },
      "dest_area_code": {
        "type": "keyword"
      },
      "dest_city": {
        "type": "keyword"
      },
      "dest_country_code": {
        "type": "keyword"
      },
      "dest_country_code3": {
        "type": "keyword"
      },
      "dest_country_name": {
        "type": "keyword"
      },
      "dest_dma_code": {
        "type": "keyword"
      },
      "dest_ip": {
        "type": "keyword"
      },
      "dest_latitude": {
        "type": "keyword"
      },
      "dest_longitude": {
        "type": "keyword"
      },
      "dest_metro_code": {
        "type": "keyword"
      },
      "dest_org": {
        "type": "keyword"
      },
      "dest_port": {
        "type": "keyword"
      },
      "dest_postal_code": {
        "type": "keyword"
      },
      "dest_region": {
        "type": "keyword"
      },
      "dest_region_name": {
        "type": "keyword"
      },
      "dest_time_zone": {
        "type": "keyword"
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
      "src_area_code": {
        "type": "keyword"
      },
      "src_city": {
        "type": "keyword"
      },
      "src_country_code": {
        "type": "keyword"
      },
      "src_country_code3": {
        "type": "keyword"
      },
      "src_country_name": {
        "type": "keyword"
      },
      "src_dma_code": {
        "type": "keyword"
      },
      "src_ip": {
        "type": "keyword"
      },
      "src_latitude": {
        "type": "keyword"
      },
      "src_longitude": {
        "type": "keyword"
      },
      "src_metro_code": {
        "type": "keyword"
      },
      "src_org": {
        "type": "keyword"
      },
      "src_port": {
        "type": "keyword"
      },
      "src_postal_code": {
        "type": "keyword"
      },
      "src_region": {
        "type": "keyword"
      },
      "src_region_name": {
        "type": "keyword"
      },
      "src_time_zone": {
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
      },
      "src_ip_geo.city_name": {
        "type": "keyword"
      },
      "src_ip_geo.region_name": {
        "type": "keyword"
      },
      "src_ip_geo.timezone": {
        "type": "keyword"
      },
      "src_ip_geo.country_name": {
        "type": "keyword"
      },
      "src_ip_geo"  : {
        "type" : "object",
        "dynamic": true,
        "properties" : {
          "location" : { "type" : "geo_point" }
        }
      },
      "dst_ip_geo.city_name": {
        "type": "keyword"
      },
      "dst_ip_geo.region_name": {
        "type": "keyword"
      },
      "dst_ip_geo.timezone": {
        "type": "keyword"
      },
      "dst_ip_geo.country_name": {
        "type": "keyword"
      },
      "dst_ip_geo"  : {
        "type" : "object",
        "dynamic": true,
        "properties" : {
          "location" : { "type" : "geo_point" }
        }
      }
    }
  }
}
EOF
