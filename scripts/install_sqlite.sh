#!/usr/bin/env bash

set -e
set -x
SCRIPTS=`dirname "$(readlink -f "$0")"`
MHN_HOME=$SCRIPTS/..

if [ -f /etc/debian_version ]; then
    OS=Debian  # XXX or Ubuntu??
    apt-get update
    apt-get -y install sqlite
    exit 0

elif [ -f /etc/redhat-release ]; then
    OS=RHEL

    yum update
    yum -y install epel-release
    yum -y groupinstall "Development tools"

    wget https://sqlite.org/2016/sqlite-autoconf-3100100.tar.gz
    tar -xvzf sqlite-autoconf-3100100.tar.gz
    cd sqlite-autoconf-3100100
    ./configure
    make && make install
    echo "sqlite install complete"

    ldconfig

else
    echo "Unknown OS. Exiting"
    exit -1

fi