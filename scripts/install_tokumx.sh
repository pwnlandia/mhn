#!/bin/bash

apt-key adv --keyserver keyserver.ubuntu.com --recv-key 505A7412
echo "deb [arch=amd64] http://s3.amazonaws.com/tokumx-debs $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/tokumx.list
apt-get update
apt-get -y install tokumx
