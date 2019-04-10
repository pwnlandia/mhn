#!/bin/bash

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

ufw allow https
ufw allow http
ufw allow ssh
ufw allow 3000
ufw allow 10000

while true;
do
    echo "WARNING: If SSH port (22) is incorrect you may lock yourself out."
    echo "Do you want to enable UFW? (y/n) "
    read UFW
    if [ "$UFW" == "y" -o "$UFW" == "Y" ]
    then
        ufw enable
        ufw status
        break
    elif [ "$UFW" == "n" -o "$UFW" == "N" ]
    then
        ufw disable
        echo "UFW configured but disabled."
        echo "Please correct and verify firewall rules before enabling UFW with:"
        echo "    sudo ufw enable"
        break
    fi
done



