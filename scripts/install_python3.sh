#!/usr/bin/env bash
#!/bin/bash
set -e
set -x

SCRIPTDIR=`dirname "$(readlink -f "$0")"`
MHN_HOME=$SCRIPTDIR/..

if [ -f /etc/debian_version ]; then
    OS=Debian  # XXX or Ubuntu??
    INSTALLER='apt-get'
    #fixme

elif [ -f /etc/redhat-release ]; then
    OS=RHEL

    yum -y update
    yum -y groupinstall "Development tools"
    yum -y install openssl-devel

    wget --no-check-certificate https://www.python.org/ftp/python/3.4.4/Python-3.4.4.tar.xz
    tar xf Python-3.4.4.tar.xz
    cd Python-3.4.4
    ./configure --prefix=/opt/dionaea/  --enable-shared --with-computed-gotos --enable-ipv6
    #make && make altinstall
    make && make install


else
    echo -e "ERROR: Unknown OS\nExiting!"
    exit -1
fi