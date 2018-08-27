#!/bin/bash
set -e
set -x

SCRIPTDIR=`dirname "$(readlink -f "$0")"`
MHN_HOME=$SCRIPTDIR/..

if [ -f /etc/debian_version ]; then
    OS=Debian  # XXX or Ubuntu??
    INSTALLER='apt-get'

elif [ -f /etc/redhat-release ]; then
    OS=RHEL
    export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PATH
    yum -y update
    yum -y groupinstall "Development tools"
    yum -y install openssl-devel wget

    if  [ ! -f /usr/local/bin/python2.7 ]; then
        wget --no-check-certificate https://www.python.org/ftp/python/2.7.6/Python-2.7.6.tar.xz
        tar xf Python-2.7.6.tar.xz
        cd Python-2.7.6
        ./configure --prefix=/usr/local
        make && make install
    fi

    if  [ ! -f /usr/local/bin/pip2.7 ]; then
        #install pip
        wget https://bootstrap.pypa.io/ez_setup.py
        /usr/local/bin/python2.7 ./ez_setup.py install
        /usr/local/bin/easy_install-2.7 pip

        #install virtualenv
        /usr/local/bin/pip2.7 install virtualenv
    fi

else
    echo -e "ERROR: Unknown OS\nExiting!"
    exit -1
fi
