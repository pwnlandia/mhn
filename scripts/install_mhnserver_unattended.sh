#!/bin/bash

set -e

if test -f "../server/config.py"; then
    ./install_mhnserver.sh
else
    echo "../server/config.py does not exist. Please create the configuration file first using the generateconfig.py script."
    exit 1
fi