#!/bin/bash

if [ "$(whoami)" != "root" ]
then
    echo "You must be root to run this script"
    exit 1
fi

SCRIPTS=$(dirname "$0")

echo "========= Installing hpfeeds ========="
${SCRIPTS}/install_hpfeeds.sh

echo "========= Installing menmosyne ========="
${SCRIPTS}/install_mnemosyne.sh

echo "========= Installing Honeymap ========="
${SCRIPTS}/install_honeymap.sh

echo "========= Installing MHN Server ========="
${SCRIPTS}/install_mhnserver.sh

echo "========= MHN Install Finished ========="

while true;
do
    echo -n "Would you like to integrate with Splunk? (y/n) "
    read SPLUNK
    if [ "$SPLUNK" == "y" -o "$SPLUNK" == "Y" ]
    then
        echo -n "Splunk Forwarder Host: "
        read SPLUNK_HOST
        echo -n "Splunk Forwarder Port: "
        read SPLUNK_PORT
        echo "The Splunk Universal Forwarder will send all MHN logs to $SPLUNK_HOST:$SPLUNK_PORT"
        ${SCRIPTS}/install_splunk_universalforwarder.sh "$SPLUNK_HOST" "$SPLUNK_PORT"
        ${SCRIPTS}/install_hpfeeds-logger-splunk.sh
        break
    elif [ "$SPLUNK" == "n" -o "$SPLUNK" == "N" ]
    then
        echo "Skipping Splunk integration"
        echo "The splunk integration can be completed at a later time by running this:"
        echo "    cd /opt/mhn/scripts/"
        echo "    sudo ./install_splunk_universalforwarder.sh <SPLUNK_HOST> <SPLUNK_PORT>"
        echo "    sudo ./install_hpfeeds-logger-splunk.sh"
        break
    fi
done

    

