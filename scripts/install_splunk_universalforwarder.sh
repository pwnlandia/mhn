#!/bin/bash

# ref: http://docs.splunk.com/Documentation/Splunk/6.2.2/Forwarding/Deployanixdfmanually#Install_the_universal_forwarder

set -e
set -x

SPLUNK_HOST="$1"
SPLUNK_PORT="$2"
SPLUNK_USER="$3"
SPLUNK_PASS="$4"

if [ -z "$SPLUNK_HOST" -o -z "$SPLUNK_PORT" -o -z "$SPLUNK_USER" -o -z "$SPLUNK_PASS" ]
then
	echo "Usage: $0 <SPLUNK_HOST> <SPLUNK_PORT> <SPLUNK_USER> <SPLUNK_PASS>"
	exit 1
fi

cd /tmp/

FILENAME="splunkforwarder-6.2.2-255606-linux-2.6-amd64.deb"
rm -f "${FILENAME}"
wget -O "${FILENAME}" "http://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=Linux&version=6.2.2&product=universalforwarder&filename=${FILENAME}&wget=true"
sudo dpkg -i "${FILENAME}"

export SPLUNK_HOME="/opt/splunk"
export PATH="$PATH:$SPLUNK_HOME/bin"
splunk start --accept-license
splunk enable boot-start

splunk add forward-server "${SPLUNK_HOST}:${SPLUNK_PORT}" -auth "${SPLUNK_USER}:${SPLUNK_PASS}"

splunk add monitor /var/log/mhn/

# might want to do this...
# splunk add forward-server <host>:<port> -ssl-cert-path /path/ssl.crt -ssl-root-ca-path /path/ca.crt -ssl-password <password>
