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

wget $server_url/static/registration.txt -O registration.sh
chmod 755 registration.sh
# Note: this will export the HPF_* variables
. ./registration.sh $server_url $deploy_key "wordpot"

apt-get update
apt-get -y install git python-pip supervisor
pip install virtualenv

# Get the Wordpot source
cd /opt
git clone https://github.com/threatstream/wordpot.git
cd wordpot

virtualenv env
. env/bin/activate
pip install -r requirements.txt

cp wordpot.conf wordpot.conf.bak
sed -i '/HPFEEDS_.*/d' wordpot.conf
sed -i "s/^HOST\s.*/HOST = '0.0.0.0'/" wordpot.conf

cat >> wordpot.conf <<EOF
HPFEEDS_ENABLED = True
HPFEEDS_HOST = '$HPF_HOST'
HPFEEDS_PORT = $HPF_PORT
HPFEEDS_IDENT = '$HPF_IDENT'
HPFEEDS_SECRET = '$HPF_SECRET'
HPFEEDS_TOPIC = 'wordpot.events'
EOF

# Config for supervisor.
cat > /etc/supervisor/conf.d/wordpot.conf <<EOF
[program:wordpot]
command=/opt/wordpot/env/bin/python /opt/wordpot/wordpot.py 
directory=/opt/wordpot
stdout_logfile=/opt/wordpot/wordpot.out
stderr_logfile=/opt/wordpot/wordpot.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

supervisorctl update
