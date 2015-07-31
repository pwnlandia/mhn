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
