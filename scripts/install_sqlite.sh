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
    export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PATH
    yum -y update
    yum -y install epel-release wget
    yum -y groupinstall "Development tools"

    wget https://www.sqlite.org/2017/sqlite-autoconf-3180000.tar.gz
    tar -xvzf sqlite-autoconf-3180000.tar.gz
    cd sqlite-autoconf-3180000
    ./configure
    make && make install

    ldconfig /usr/local/lib/
    ldconfig /usr/lib64/qt4/plugins/sqldrivers
else
    echo -e "Unknown OS. Exiting"
    exit -1

fi
