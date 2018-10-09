#!/bin/bash

# Install MongoDB for Ubuntu 18.04

set -e
set -x

apt update
apt install -y mongodb
