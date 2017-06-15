Modern Honey Network
==========================

Multi-snort and honeypot sensor management, uses a network of VMs, small footprint SNORT installations, stealthy dionaeas, and a centralized server for management.

For questions regarding installation please review the [MHN Troubleshooting Guide](https://github.com/threatstream/mhn/wiki/MHN-Troubleshooting-Guide).  Search past questions on the [modern-honey-network Google Group](https://groups.google.com/forum/#!forum/modern-honey-network).  Or send emails to <modern-honey-network@googlegroups.com>.


### HONEYPOT

Deployed sensors with intrusion detection software installed: Snort, Kippo, Conpot, and Dionaea. 

### MANAGEMENT SERVER

Flask application that exposes an HTTP API that honeypots can use to:
- Download a deploy script
- Connect and register
- Download snort rules
- Send intrusion detection logs

It also allows systems administrators to:
- View a list of new attacks
- Manage snort rules: enable, disable, download


### INSTALLING SERVER (tested Ubuntu 12.0.4.3 x86_64 and Centos 6.7)

- The MHN server is supported on Ubuntu 12, Ubuntu 14, and Centos 6.7.  
- Ubuntu 16 is not supported at this time.  
- Other flavors/versions of Linux may work, but are generally not tested or supported.

Note: if you run into trouble during the install, please checkout the [troubleshooting guide](https://github.com/threatstream/MHN/wiki/MHN-Troubleshooting-Guide) on the wiki.  If you only want to experiment with MHN on some virtual machines, please check out the [Getting up and Running with Vagrant](https://github.com/threatstream/mhn/wiki/Getting-up-and-running-using-Vagrant) guide on the wiki.

Install Git

    # on Debian or Ubuntu
    $ sudo apt-get install git -y
    
    # on Centos or RHEL
    $ sudo yum install -y git

Install MHN
    
    $ cd /opt/
    $ sudo git clone https://github.com/threatstream/mhn.git
    $ cd mhn/

Run the following script to complete the installation.  While this script runs, you will
be prompted for some configuration options.  See below for how this looks.

    $ sudo ./install.sh


### Configuration:
    
    ===========================================================
    MHN Configuration
    ===========================================================
    Do you wish to run in Debug mode?: y/n n
    Superuser email: YOUR_EMAIL@YOURSITE.COM
    Superuser password: 
    Server base url ["http://1.2.3.4"]: 
    Honeymap url ["http://1.2.3.4:3000"]:
    Mail server address ["localhost"]: 
    Mail server port [25]: 
    Use TLS for email?: y/n n
    Use SSL for email?: y/n n
    Mail server username [""]: 
    Mail server password [""]: 
    Mail default sender [""]: 
    Path for log file ["mhn.log"]: 


### Running

If the installation scripts ran successfully, you should have a number of services running on your MHN server.  See below for checking these.

    user@precise64:/opt/mhn/scripts$ sudo /etc/init.d/nginx status
     * nginx is running
    user@precise64:/opt/mhn/scripts$ sudo /etc/init.d/supervisor status
     is running
    user@precise64:/opt/mhn/scripts$ sudo supervisorctl status
    geoloc                           RUNNING    pid 31443, uptime 0:00:12
    honeymap                         RUNNING    pid 30826, uptime 0:08:54
    hpfeeds-broker                   RUNNING    pid 10089, uptime 0:36:42
    mhn-celery-beat                  RUNNING    pid 29909, uptime 0:18:41
    mhn-celery-worker                RUNNING    pid 29910, uptime 0:18:41
    mhn-collector                    RUNNING    pid 7872,  uptime 0:18:41
    mhn-uwsgi                        RUNNING    pid 29911, uptime 0:18:41
    mnemosyne                        RUNNING    pid 28173, uptime 0:30:08

### Running MHN Behind a Proxy

For each of the files below, make sure the proxy settings are added (and obviously change the user/pass/domain/port)

These need to be set for both the MHN server and the honey systems you intend to deploy on (assuming the honeypots are behind the firewall).

## /etc/environment

```
ALL_PROXY=http://user:password@your.corporate.proxy.hostname.com:8080
HTTP_PROXY=http://user:password@your.corporate.proxy.hostname.com:8080
HTTPS_PROXY=http://user:password@your.corporate.proxy.hostname.com:8080
http_proxy=http://user:password@your.corporate.proxy.hostname.com:8080
https_proxy=http://user:password@your.corporate.proxy.hostname.com:8080
```

## /etc/apt/apt.conf.d/95proxies

```
Acquire::http::proxy "http://user:password@your.corporate.proxy.hostname.com:8080";
Acquire::https::proxy "http://user:password@your.corporate.proxy.hostname.com:8080";
Acquire::ftp::proxy "http://user:password@your.corporate.proxy.hostname.com:8080";
```


## ~/.gitconfig

```
[http]
	proxy = http://user:password@your.corporate.proxy.hostname.com:8080
```

# Commands:

These commands will make the above changes. 

```
PROXY='http://user:password@your.corporate.proxy.hostname.com:8080'

grep -F "$PROXY" /etc/environment || cat >> /etc/environment <<EOF
ALL_PROXY=$PROXY
http_proxy=$PROXY
HTTP_PROXY=$PROXY
https_proxy=$PROXY
HTTPS_PROXY=$PROXY
EOF

cat > /etc/apt/apt.conf.d/95proxies << EOF
Acquire::http::proxy "$PROXY";
Acquire::https::proxy "$PROXY";
Acquire::ftp::proxy "$PROXY";
EOF

git config --global --add http.proxy "$PROXY"

```

If done immediately before installing MHN or a honeypot, be sure to run this right after the above commands:

```
source /etc/environment
```


### Manual Password Reset

If email based password resets are not working for you, here is another method.

    $ cd $MHN_HOME
    $ source env/bin/activate
    $ cd server
    $ python manual_password_reset.py 
    Enter email address: YOUR_USER@YOUR_SITE.com
    Enter new password: 
    Enter new password (again): 
    user found, updating password

### Deploying honeypots with MHN

MHN was designed to make scalable deployment of honeypots easier.  Here are the steps for deploying a honeypot with MHN:

1. Login to your MHN server web app.
2. Click the "Deploy" link in the upper left hand corner.
3. Select a type of honeypot from the drop down menu (e.g. "Ubuntu 12.04 Dionaea").
4. Copy the deployment command.
5. Login to a honeypot server and run this command as root.
6. That's it!

### Integration with Splunk and ArcSight

hpfeeds-logger can be used to integrate MHN with Splunk and ArcSight.  Installation below.

#### Splunk


    cd /opt/mhn/scripts/
    sudo ./install_hpfeeds-logger-splunk.sh

This will log the events as key/value pairs to /var/log/mhn-splunk.log.  This log should be monitored by the SplunkUniveralForwarder.

#### Arcsight


    cd /opt/mhn/scripts/
    sudo ./install_hpfeeds-logger-arcsight.sh

This will log the events as CEF to /var/log/mhn-arcsight.log


### Data

The MHN server reports anonymized attack data back to Anomali, Inc. (formerly known as ThreatStream).  If you are interested in this data please contact: <modern-honey-network@googlegroups.com>.  This data reporting can be disabled by running the following command from the MHN server after completing the initial installation steps outlined above: `/opt/mhn/scripts/disable_collector.sh`

### Support or Contact
MHN is an open source project brought to you by the passionate folks at Anomali, Inc. Please check out our troubleshooting guide on the wiki. We will also lend a hand, if needed. Find us at: <modern-honey-network@googlegroups.com>.

### Credit and Thanks
MHN leverages and extends upon several awesome projects by the Honeynet project. Please show them your support by way of donation.


## LICENSE

Modern Honeypot Network

Copyright (C) 2017 - Anomali, Inc.

This program free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
