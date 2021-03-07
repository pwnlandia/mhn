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

apt update
apt install -y git supervisor

####################################################################
# Install a decent version of golang
if [ "$(uname -m)" == "x86_64" ] ;
then
    GO_PACKAGE="go1.12.6.linux-amd64.tar.gz"
elif [ "$(uname -m)" == "armv7l" ] || [ "$(uname -m)" == "armv6l" ];
then
    GO_PACKAGE="go1.12.6.linux-armv6l.tar.gz"
else
    GO_PACKAGE="go1.12.6.linux-386.tar.gz"
fi

cd /usr/local/
wget https://storage.googleapis.com/golang/${GO_PACKAGE}
tar zxf ${GO_PACKAGE} && rm ${GO_PACKAGE}

cd /usr/bin/
for X in /usr/local/go/bin/*; 
do 
    echo $X; 
    ln -s $X; 
done
####################################################################

export GO111MODULE=on

# Get the magenpot source
cd /opt
git clone https://github.com/trevorleake/magenpot.git
cd magenpot
git checkout b4f113b

go build

# Register the sensor with the MHN server.
wget $server_url/static/registration.txt -O registration.sh
chmod 755 registration.sh
# Note: this will export the HPF_* variables
. ./registration.sh $server_url $deploy_key "agave"

cat > config.toml<<EOF
# magenpot Configuration File

[magento]
# Port to server the honeypot webserver on.
# Note: Ports under 1024 require sudo.
port = 80

site_name = "Magenpot"
name_randomizer = true

# Allows you to set the magento_version file content to spoof different versions.
# Always served as "http[s]://server/magento_version"
magento_version_text = "Magento/2.3 (Enterprise)"

# TODO: Optional SSL/TLS Cert

[hpfeeds]
enabled = true
host = "$HPF_HOST"
port = $HPF_PORT
ident = "$HPF_IDENT"
auth = "$HPF_SECRET"
channel = "agave.events"

[fetch_public_ip]
enabled = true
urls = ["http://icanhazip.com/", "http://ifconfig.me/ip"]

EOF

# Config for supervisor.
cat > /etc/supervisor/conf.d/magenpot.conf <<EOF
[program:magenpot]
command=/opt/magenpot/magenpot
directory=/opt/magenpot
stdout_logfile=/opt/magenpot/magenpot.out
stderr_logfile=/opt/magenpot/magenpot.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

supervisorctl update
supervisorctl restart all



