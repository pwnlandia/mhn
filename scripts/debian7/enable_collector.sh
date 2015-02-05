#!/bin/bash

sudo sed -i'' 's/autostart=false/autostart=true/g'     /etc/supervisor/conf.d/mhn-collector.conf
sudo sed -i'' 's/autorestart=false/autorestart=true/g' /etc/supervisor/conf.d/mhn-collector.conf
sudo supervisorctl update

