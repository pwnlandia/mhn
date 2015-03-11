#!/bin/bash

set -e

scripts_directory="$(dirname $(readlink -f ${BASH_SOURCE}))"
mhn_directory="$(dirname ${scripts_directory})"

if test -f "${mhn_directory}/server/config.py"; then
    "${mhn_directory}/scripts/install_mhnserver.sh"
else
    echo "${mhn_directory}/server/config.py does not exist. Please create the configuration file first using the generateconfig.py script."
    exit 1
fi
