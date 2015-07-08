#!/bin/bash

if [ "$(whoami)" != "root" ]
then
    echo "You must be root to run this script"
    exit 1
fi

set -e

MHN_HOME=$(dirname "$0")
SCRIPTS="$MHN_HOME/scripts"
cd "$SCRIPTS"

echo "[`date`] Starting Installation of all MHN packages"

echo "[`date`] ========= Installing hpfeeds ========="
./install_hpfeeds.sh

echo "[`date`] ========= Installing menmosyne ========="
./install_mnemosyne.sh

echo "[`date`] ========= Installing Honeymap ========="
./install_honeymap.sh

echo "[`date`] ========= Installing MHN Server ========="
./install_mhnserver.sh

echo "[`date`] ========= MHN Server Install Finished ========="
echo ""

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
        ./install_splunk_universalforwarder.sh "$SPLUNK_HOST" "$SPLUNK_PORT"
        ./install_hpfeeds-logger-splunk.sh
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




while true;
do
    echo -n "Would you like to install ELK? (y/n) "
    read ELK
    if [ "$ELK" == "y" -o "$ELK" == "Y" ]
    then
        ./install_elk.sh
        break
    elif [ "$ELK" == "n" -o "$ELK" == "N" ]
    then
        echo "Skipping ELK installation"
        echo "The ELK installationg can be completed at a later time by running this:"
        echo "    cd /opt/mhn/scripts/"
        echo "    sudo ./install_elk.sh"
        break
    fi
done

echo "[`date`] Completed Installation of all MHN packages"
