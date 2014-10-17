#!/bin/bash
sudo /etc/init.d/nginx status
echo "supervisor:"
sudo /etc/init.d/supervisor status
sudo supervisorctl status
