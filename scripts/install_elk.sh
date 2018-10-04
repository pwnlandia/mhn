#!/bin/bash

set -x
set -e

DIR=`dirname "$0"`
$DIR/install_hpfeeds-logger-json.sh

# install Java
apt-get install -y python-software-properties
add-apt-repository -y ppa:webupd8team/java
apt-get update
apt-get -y install oracle-java8-installer

# Install ES
wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch |  apt-key add -
echo 'deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main' |  tee /etc/apt/sources.list.d/elasticsearch.list
apt-get update
apt-get -y install elasticsearch=1.4.4
sed -i '/network.host/c\network.host\:\ localhost' /etc/elasticsearch/elasticsearch.yml
service elasticsearch restart
update-rc.d elasticsearch defaults 95 10

# Install Kibana
mkdir /tmp/kibana
cd /tmp/kibana ;
wget https://download.elasticsearch.org/kibana/kibana/kibana-4.0.1-linux-x64.tar.gz
tar xvf kibana-4.0.1-linux-x64.tar.gz
sed -i '/0.0.0.0/c\host\:\ localhost' /etc/elasticsearch/elasticsearch.yml
mkdir -p /opt/kibana
cp -R /tmp/kibana/kibana-4*/* /opt/kibana/
rm -rf /tmp/kibana/kibana-4*

cat > /etc/supervisor/conf.d/kibana.conf <<EOF
[program:kibana]
command=/opt/kibana/bin/kibana
directory=/opt/kibana/
stdout_logfile=/var/log/mhn/kibana.log
stderr_logfile=/var/log/mhn/kibana.err
autostart=true
autorestart=true
startsecs=10
EOF

# Install Logstash

echo 'deb http://packages.elasticsearch.org/logstash/1.5/debian stable main' |  tee /etc/apt/sources.list.d/logstash.list
apt-get update
apt-get install logstash
cd /opt/logstash

cat > /opt/logstash/mhn.conf <<EOF

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
      database => "/opt/GeoLiteCity.dat"
      add_field => [ "[src_ip_geo][coordinates]", "%{[src_ip_geo][longitude]}" ]
      add_field => [ "[src_ip_geo][coordinates]", "%{[src_ip_geo][latitude]}"  ]
  }
  mutate {
    convert => [ "[src_ip_geo][coordinates]", "float"]
  }

  geoip {
    source => "dst_ip"
    target => "dst_ip_geo"
    database => "/opt/GeoLiteCity.dat"
    add_field => [ "[dst_ip_geo][coordinates]", "%{[dst_ip_geo][longitude]}" ]
    add_field => [ "[dst_ip_geo][coordinates]", "%{[dst_ip_geo][latitude]}"  ]
  }

  mutate {
      convert => [ "[dst_ip_geo][coordinates]", "float"]
    }
}

output {
  elasticsearch {
    host => "127.0.0.1"
    port => 9200
    protocol => "http"
    index => "mhn-%{+YYYYMMddHH00}"
    index_type => "event"
    template_name => "mhn_event"
    template => "/opt/logstash/mhn-template.json"
    template_overwrite => true
    manage_template => true
  }
}

EOF

cat > /opt/logstash/mhn-template.json <<EOF
{
  "template": "mhn-*",
  "settings": {
    "number_of_shards": 5,
    "number_of_replicas": 0,
    "refresh_interval": "30s"
  },
  "mappings": {
    "_default_": {
      "_source": {
        "enabled": true
      },
      "properties": {}
    },
    "event": {
      "properties": {
        "app": {
          "type": "string",
          "index": "not_analyzed"
        },
        "command": {
          "type": "string",
          "index": "analyzed"
        },
        "dest_area_code": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_city": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_country_code": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_country_code3": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_country_name": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_dma_code": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_ip": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_latitude": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_longitude": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_metro_code": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_org": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_port": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_postal_code": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_region": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_region_name": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dest_time_zone": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dionaea_action": {
          "type": "string",
          "index": "not_analyzed"
        },
        "direction": {
          "type": "string",
          "index": "not_analyzed"
        },
        "elastichoney_form": {
          "type": "string",
          "index": "not_analyzed"
        },
        "elastichoney_payload": {
          "type": "string",
          "index": "not_analyzed"
        },
        "eth_dst": {
          "type": "string",
          "index": "not_analyzed"
        },
        "eth_src": {
          "type": "string",
          "index": "not_analyzed"
        },
        "ids_type": {
          "type": "string",
          "index": "not_analyzed"
        },
        "ip_id": {
          "type": "string",
          "index": "not_analyzed"
        },
        "ip_len": {
          "type": "string",
          "index": "not_analyzed"
        },
        "ip_tos": {
          "type": "string",
          "index": "not_analyzed"
        },
        "ip_ttl": {
          "type": "string",
          "index": "not_analyzed"
        },
        "md5": {
          "type": "string",
          "index": "not_analyzed"
        },
        "p0f_app": {
          "type": "string",
          "index": "not_analyzed"
        },
        "p0f_link": {
          "type": "string",
          "index": "not_analyzed"
        },
        "p0f_os": {
          "type": "string",
          "index": "not_analyzed"
        },
        "p0f_uptime": {
          "type": "string",
          "index": "not_analyzed"
        },
        "protocol": {
          "type": "string",
          "index": "not_analyzed"
        },
        "request_url": {
          "type": "string",
          "index": "not_analyzed"
        },
        "sensor": {
          "type": "string",
          "index": "not_analyzed"
        },
        "severity": {
          "type": "string",
          "index": "not_analyzed"
        },
        "sha512": {
          "type": "string",
          "index": "not_analyzed"
        },
        "signature": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_area_code": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_city": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_country_code": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_country_code3": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_country_name": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_dma_code": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_ip": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_latitude": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_longitude": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_metro_code": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_org": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_port": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_postal_code": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_region": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_region_name": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_time_zone": {
          "type": "string",
          "index": "not_analyzed"
        },
        "ssh_password": {
          "type": "string",
          "index": "not_analyzed"
        },
        "ssh_username": {
          "type": "string",
          "index": "not_analyzed"
        },
        "ssh_version": {
          "type": "string",
          "index": "not_analyzed"
        },
        "tcp_flags": {
          "type": "string",
          "index": "not_analyzed"
        },
        "tcp_len": {
          "type": "string",
          "index": "not_analyzed"
        },
        "transport": {
          "type": "string",
          "index": "not_analyzed"
        },
        "type": {
          "type": "string",
          "index": "not_analyzed"
        },
        "udp_len": {
          "type": "string",
          "index": "not_analyzed"
        },
        "url": {
          "type": "string",
          "index": "not_analyzed"
        },
        "user_agent": {
          "type": "string",
          "index": "not_analyzed"
        },
        "vendor_product": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_ip_geo.city_name": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_ip_geo.region_name": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_ip_geo.timezone": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_ip_geo.country_name": {
          "type": "string",
          "index": "not_analyzed"
        },
        "src_ip_geo"  : {
          "type" : "object",
          "dynamic": true,
          "properties" : {
            "location" : { "type" : "geo_point" }
          }
        },
        "dst_ip_geo.city_name": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dst_ip_geo.region_name": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dst_ip_geo.timezone": {
          "type": "string",
          "index": "not_analyzed"
        },
        "dst_ip_geo.country_name": {
          "type": "string",
          "index": "not_analyzed"
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
}
EOF

cat > /etc/supervisor/conf.d/logstash.conf <<EOF
[program:logstash]
command=/opt/logstash/bin/logstash -f mhn.conf
directory=/opt/logstash/
stdout_logfile=/var/log/mhn/logstash.log
stderr_logfile=/var/log/mhn/logstash.err
autostart=true
autorestart=true
startsecs=10
EOF

supervisorctl update
