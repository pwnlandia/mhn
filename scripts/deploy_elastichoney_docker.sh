set -e
set -x

if [ $# -ne 2 ]
    then
        echo "Wrong number of arguments supplied."
        echo "Usage: $0 <server_url> <deploy_key>."
        exit 1
fi

server_url=$1
deploy_key=$2

apt-get update
apt-get -y install docker.io supervisor


# Get the elastichoney docker image
docker pull pwnlandia/elastichoney

# Register the sensor with the MHN server.
wget $server_url/static/registration.txt -O registration.sh
chmod 755 registration.sh
# Note: this will export the HPF_* variables
. ./registration.sh $server_url $deploy_key "elastichoney"

mkdir /opt/elastichoney
cat > /opt/elastichoney/config.json<<EOF
{
    "logfile" : "/opt/elastichoney/elastichoney.log",
    "use_remote" : false,
    "remote" : {
        "url" : "http://example.com",
        "use_auth" : false,
        "auth" : {
            "username" : "",
            "password" : ""
        }
    },
    "hpfeeds": {
        "enabled": true,
        "host": "$HPF_HOST",
        "port": $HPF_PORT,
        "ident": "$HPF_IDENT",
        "secret": "$HPF_SECRET",
        "channel": "elastichoney.events"
    },
    "instance_name" : "Green Goblin",
    "anonymous" : false,
    "spoofed_version"  : "1.4.1",
    "public_ip_url": "http://icanhazip.com"
}
EOF

# Config for supervisor.
cat > /etc/supervisor/conf.d/elastichoney.conf <<EOF
[program:elastichoney]
command=docker run -p 9200:9200 -p 10000:10000 -v /opt/elastichoney:/etc/elastichoney pwnlandia/elastichoney:latest
directory=/opt/elastichoney
stdout_logfile=/opt/elastichoney/elastichoney.out
stderr_logfile=/opt/elastichoney/elastichoney.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

supervisorctl update
