# Proxy testing

## Setup

    # on your local workstation
    vagrant up ubuntu-14 # proxy node
    vagrant up server # MHN server

    # Waiting for the 2 VMs to be setup (proxy VM will take a couple minutes).    

    vagrant ssh ubuntu-14
    sudo su -
    cd /vagrant/scripts/proxy
    ./proxy-setup.sh
    exit

    vagrant ssh server
    
    # now, put the iptables rules in place
    sudo su -
    cd /vagrant/scripts/proxy
    ./iptables-rules.sh
    
    # see example console output below to see how to test the iptables
    # notice the IP being connected to before and after the proxy settings

    # enable the proxy settings
    source proxy.rc

## Example:

    [root@ubuntu-14 proxy]# ./iptables-rules.sh
    [root@ubuntu-14 proxy]# wget http://www.google.com
    --2014-07-08 18:23:19--  http://www.google.com/
    Resolving www.google.com... 74.125.239.113, 74.125.239.112, 74.125.239.114, ...
    Connecting to www.google.com|74.125.239.113|:80... ^C
    [root@ubuntu-14 proxy]#
    [root@ubuntu-14 proxy]# . proxy_settings.rc
    [root@ubuntu-14 proxy]# wget http://www.google.com
    --2014-07-08 18:23:58--  http://www.google.com/
    Connecting to 10.200.100.100:3128... connected.
    Proxy request sent, awaiting response... 200 OK
    Length: unspecified [text/html]
    Saving to: “index.html”

        [  <=>                                                                                                                                                              ] 19,352      56.1K/s   in 0.3s

    2014-07-08 18:24:04 (56.1 KB/s) - “index.html” saved [19352]


Clearing the iptables rules (in case of needing to install packages, etc)

    sudo iptables -F

