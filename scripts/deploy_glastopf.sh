#!/bin/bash

set -e
set -x

if [ $# -ne 2 ]
    then
        echo "Wrong number of arguments supplied."
        echo "Usage: $0 <server_url> <deploy_key>."
        exit 1
fi

# Check if Ubuntu 18.04 or 16.04
if [ "$(lsb_release -r -s)" != "18.04" ] && [ "$(lsb_release -r -s)" != "16.04" ]; then
    echo "WARNING: This operating system may not be supported by this script."
    echo "Continue? (y/n)"
    read PROMPT
    if [ "$PROMPT" == "n" -o "$PROMPT" == "N" ]                               
    then                                                                        
        exit
    fi    
fi

server_url=$1
deploy_key=$2
GLASTOPF_HOME=/opt/glastopf

# Update repository
apt-get update

# Install Prerequisites
if [ "$(lsb_release -r -s)" == "14.04" ]; then
    apt-get install -y python2.7 python-openssl python-gevent libevent-dev python2.7-dev build-essential make python-chardet python-requests python-sqlalchemy python-lxml python-beautifulsoup mongodb python-pip python-dev python-setuptools g++ git php5 php5-dev liblapack-dev gfortran libmysqlclient-dev libxml2-dev libxslt-dev supervisor
else
    apt-get install -y apache2 python2.7 python-openssl python-gevent libevent-dev python2.7-dev build-essential make python-chardet python-requests python-sqlalchemy python-lxml python-beautifulsoup mongodb python-pip python-dev python-setuptools g++ git php php-dev liblapack-dev gfortran libmysqlclient-dev libxml2-dev libxslt-dev supervisor
fi

pip install -e git+https://github.com/pwnlandia/hpfeeds.git#egg=hpfeeds-dev

# Install and configure the PHP sandbox
cd /opt
git clone git://github.com/mushorg/BFR.git
cd BFR
phpize
./configure --enable-bfr
make && make install

# Updated php.ini to add bfr.so
if [ "$(lsb_release -r -s)" == "14.04" ]; then
    BFR_BUILD_OUTPUT=`find /usr/lib/php5/ -type f -name "bfr.so" | awk -F"/" '{print $5}'`
    echo "zend_extension = /usr/lib/php5/$BFR_BUILD_OUTPUT/bfr.so" >> /etc/php5/apache2/php.ini
else
    BFR_BUILD_OUTPUT=`find /usr/lib/php/ -type f -name "bfr.so" | awk -F"/" '{print $5}'`
    echo "zend_extension = /usr/lib/php/$BFR_BUILD_OUTPUT/bfr.so" >> /etc/php/7.0/fpm/php.ini
fi

# Stop apache2 and disable it from start up
service apache2 stop
update-rc.d -f  apache2 remove

# Upgrade python-greenlet
pip install --upgrade greenlet

# Install glastopf
pip install --upgrade pgen
pip install --upgrade cython
pip uninstall --yes setuptools
git clone https://github.com/mushorg/glastopf.git $GLASTOPF_HOME
cd $GLASTOPF_HOME
python setup.py install

# Register the sensor with the MHN server.
wget $server_url/static/registration.txt -O registration.sh
chmod 0755 registration.sh
# Note: This will export the HPF_* variables
. ./registration.sh $server_url $deploy_key "glastopf"

# Add the modified glastopf.cfg
cat > $GLASTOPF_HOME/glastopf.cfg <<EOF
[webserver]
host = 0.0.0.0
port = 80
uid = nobody
gid = nogroup
proxy_enabled = False

[ssl]
enabled = False
certfile = 
keyfile =

#Generic logging for general monitoring
[logging]
consolelog_enabled = False
filelog_enabled = True
logfile = log/glastopf.log

[dork-db]
enabled = True
pattern = rfi
#Extracts dorks from a online dorks service operated by The Honeynet Project
mnem_service = True

[hpfeed]
enabled = True
host = $HPF_HOST
port = $HPF_PORT
secret = $HPF_SECRET
# channels comma separated
chan_events = glastopf.events
chan_files = glastopf.files
ident = $HPF_IDENT

[main-database]
#If disabled a sqlite database will be created (db/glastopf.db)
#to be used as dork storage.
enabled = True
#mongodb or sqlalchemy connection string, ex:
#mongodb://localhost:27017/glastopf
#mongodb://james:bond@localhost:27017/glastopf
#mysql://james:bond@somehost.com/glastopf
connection_string = sqlite:///db/glastopf.db

[surfcertids]
enabled = False
host = localhost
port = 5432
user =
password =
database = idsserver

[syslog]
enabled = False
socket = /dev/log

[mail]
enabled = False
# an email notification will be sent only if a specified matched pattern is identified.
# Use the wildcard char *, to be notified every time
patterns = rfi,lfi
user =
pwd =
mail_from =
mail_to =
smtp_host = smtp.gmail.com
smtp_port = 587

[taxii]
enabled = False
host = taxiitest.mitre.org
port = 80
inbox_path = /services/inbox/default/
use_https = False
use_auth_basic = False
auth_basic_username = your_username
auth_basic_password = your_password
use_auth_certificate = False
auth_certificate_keyfile = full_path_to_keyfile
auth_certificate_certfile = full_path_to_certfile
include_contact_info = False
contact_name = ...
contact_email = ...

[logstash]
enabled = False
host = localhost
port = 5659
handler = AMQP/TCP/UDP 

[misc]
# set webserver banner
banner = Apache/2.0.48

[surface]
#https://www.google.com/webmasters/
google_meta =
#http://www.bing.com/toolbox/webmaster
bing_meta =

[sensor]
sensorid = None

[profiler]
enabled = False

[s3storage]
enabled = False
endpoint = http://localhost:8080/
aws_access_key_id = YOUR_aws_access_key_id
aws_secret_access_key = YOUR_aws_access_key_id
bucket = glastopf
region = eu-west-1
signature_version = s3	
EOF

# Set up supervisor
cat > /etc/supervisor/conf.d/glastopf.conf <<EOF
[program:glastopf]
command=/usr/bin/python /usr/local/bin/glastopf-runner
directory=$GLASTOPF_HOME
stdout_logfile=/var/log/glastopf.out
stderr_logfile=/var/log/glastopf.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

supervisorctl update
supervisorctl restart all
