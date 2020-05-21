#!/bin/bash

# Install MongoDB for the appropriate OS and version.
# Supports Ubuntu 14, 16, 18, RHEL/CentOS 6.9 and kali linux 2020.2

set -e
set -x

if [ -f /etc/debian_version ]; then

    if [ "$(lsb_release -r -s)" == "14.04" ]; then
        ./install_mongodb_ub14.sh
    elif [ "$(lsb_release -r -s)" == "16.04" ]; then
        ./install_mongodb_ub16.sh
    elif [ "$(lsb_release -r -s)" == "18.04" ]; then
        ./install_mongodb_ub18.sh
    elif [ "$(lsb_release -r -s)" == "2020.2" ]; then
	    ./install_mongodb_debian.sh
    else
        echo -e "ERROR: Unknown OS\nExiting!"
        exit -1
    fi

elif [ -f /etc/redhat-release ]; then
    ./install_mongodb_rhel69.sh
else
    echo -e "ERROR: Unknown OS\nExiting!"
    exit -1
fi
