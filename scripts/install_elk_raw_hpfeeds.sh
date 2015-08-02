#!/bin/bash

set -x
set -e

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
git clone https://github.com/aabed/logstash-input-hpfeeds.git
echo "gem \"logstash-input-hpfeeds\", :path => \"/opt/logstash/logstash-input-hpfeeds\"" >> Gemfile

bin/plugin install --no-verify
#patching hpfeeds library to work with jruby as the bool function is not implemented yet and it doesn't affect the flow
sed -ie '/Socket::Option.bool/ s/^#*/#/' /opt/logstash/vendor/bundle/jruby/1.9/gems/hpfeeds-0.1.6/lib/hpfeeds/client.rb

SECRET=`python -c 'import uuid;print str(uuid.uuid4()).replace("-","")'`
/opt/hpfeeds/env/bin/python /opt/hpfeeds/broker/add_user.py elk $SECRET "" amun.events,dionaea.connections,dionaea.capture,glastopf.events,beeswarm.hive,kippo.sessions,conpot.events,snort.alerts,kippo.alerts,wordpot.events,shockpot.events,p0f.events,suricata.events,elastichoney.events
cat > /opt/logstash/mhn-hpfeeds.conf <<EOF

input {
  hpfeeds {
    port => 10000
    ident => "elk"
    host => "localhost"
    secret => "$SECRET"
    channels => ["dionaea.connections",
    "dionaea.capture",
    "glastopf.events",
    "beeswarm.hive",
    "kippo.sessions",
    "conpot.events",
    "snort.alerts",
    "amun.events",
    "wordpot.events",
    "shockpot.events",
    "p0f.events",
    "suricata.events",
    "elastichoney.events"]
  }
}

filter {
  json {
    source => "message"
  }
}

output {
  elasticsearch {
    host => "localhost"
    protocol => "http"
    port => 9200
  }
}

EOF
cat > /etc/supervisor/conf.d/logstash-hpfeeds.conf <<EOF
[program:logstash-hpfeeds]
command=/opt/logstash/bin/logstash -f mhn-hpfeeds.conf
directory=/opt/logstash/
stdout_logfile=/var/log/mhn/logstash-hpfeeds.log
stderr_logfile=/var/log/mhn/logstash-hpfeeds.err
autostart=true
autorestart=true
startsecs=10
EOF

supervisorctl update
