Modern Honey Network
====================

MHN is a centralized server for management and data collection of honeypots. MHN
allows you to deploy sensors quickly and to collect data immediately, viewable
from a neat web interface. Honeypot deploy scripts include several common
honeypot technologies, including [Snort](https://snort.org/),
[Cowrie](http://www.micheloosterhof.com/cowrie/),
[Dionaea](https://www.edgis-security.org/single-post/dionaea-malware-honeypot), and
[glastopf](https://github.com/glastopf/), among others.

For questions regarding troubleshooting your installation, please review the
[MHN Troubleshooting
Guide](https://github.com/pwnlandia/mhn/wiki/MHN-Troubleshooting-Guide),
search past questions on the [modern-honey-network Google
Group](https://groups.google.com/forum/#!forum/modern-honey-network), or send
emails to <modern-honey-network@googlegroups.com>.


## Features

MHN is a Flask application that exposes an HTTP API that honeypots can use to:
- Download a deploy script
- Connect and register
- Download snort rules
- Send intrusion detection logs

It also allows system administrators to:
- View a list of new attacks
- Manage snort rules: enable, disable, download


## Installation

- The MHN server is supported on Ubuntu 18.04, Ubuntu 16.04, and Centos 6.9.  
- Other versions of Linux may work but are generally not tested or supported.

Note: if you run into trouble during the install, please checkout the [troubleshooting guide](https://github.com/Pwnlandia/MHN/wiki/MHN-Troubleshooting-Guide) on the wiki.  If you only want to experiment with MHN on some virtual machines, please check out the [Getting up and Running with Vagrant](https://github.com/Pwnlandia/mhn/wiki/Getting-up-and-running-using-Vagrant) guide on the wiki.

Install Git

    # on Debian or Ubuntu
    $ sudo apt install git -y
    
Install MHN
    
    $ cd /opt/
    $ sudo git clone https://github.com/pwnlandia/mhn.git
    $ cd mhn/

Run the following script to complete the installation.  While this script runs,
you will be prompted for some configuration options.  See below for how this
looks.

    $ sudo ./install.sh


### Configuration
    
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

If the installation scripts ran successfully, you should have a number of
services running on your MHN server.  See below for checking these.

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

For directions on running MHN behind a web proxy, follow the directions in the
[wiki.](https://github.com/pwnlandia/mhn/wiki/Running-MHN-Behind-a-Web-Proxy)

### Running MHN Over HTTPS

By default MHN will run without HTTPS, to configure your installation to use SSL
certificates directions can be found in the [wiki.](https://github.com/pwnlandia/mhn/wiki/Running-MHN-Over-HTTPS)

### Running MHN with Docker

Running MHN in docker is not officially supported, but it works.
The container takes a few minutes to start at the first launch to initialize.
Splunk, ArcSight and ELK are not yet supported in Docker.

#### Build it

	$ docker build -t mhn .

#### Run it

    $ docker run -d -p 10000:10000 -p 80:80 -p 3000:3000 -p 8089:8089 \
    $ --restart unless-stopped \
    $ --name mhn \
    $ -e SUPERUSER_EMAIL=root@localhost \
    $ -e SUPERUSER_PASSWORD=password \
    $ -e SERVER_BASE_URL="http://mhn" \
    $ -e HONEYMAP_URL="http://mhn:3000" \
    $ mhn
	
#### Environment variables

	SUPERUSER_EMAIL
	SUPERUSER_PASSWORD
	SERVER_BASE_URL
	HONEYMAP_URL
	DEBUG_MODE
	SMTP_HOST
	SMTP_PORT
	SMTP_TLS
	SMTP_SSL
	SMTP_USERNAME
	SMTP_PASSWORD
	SMTP_SENDER
	MHN_LOG

## Deploying honeypots with MHN

MHN was designed to make scalable deployment of honeypots easier.  Here are the
steps for deploying a honeypot with MHN:

1. Login to your MHN server web app.
2. Click the "Deploy" link in the upper left hand corner.
3. Select a type of honeypot from the drop down menu (e.g. "Ubuntu Dionaea").
4. Copy the deployment command.
5. Login to a honeypot server and run this command as root.

If the deploy script successfully completes you should see the new sensor listed
under your deployed sensor list. For a full list of supported sensors, check the list here: [List of Supported Sensors](https://github.com/pwnlandia/mhn/wiki/List-of-Supported-Sensors)

## Integration with Splunk and ArcSight

hpfeeds-logger can be used to integrate MHN with Splunk and ArcSight.

#### Splunk


    cd /opt/mhn/scripts/
    sudo ./install_hpfeeds-logger-splunk.sh

This will log the events as key/value pairs to /var/log/mhn-splunk.log.  This
log should be monitored by the SplunkUniversalForwarder.

#### Arcsight


    cd /opt/mhn/scripts/
    sudo ./install_hpfeeds-logger-arcsight.sh

This will log the events as CEF to /var/log/mhn-arcsight.log

## Data	
*NOTICE* **This section is out of date. Community data is not collected by Anomali although MHN still attempts to send this data to Anomali servers.**	

The MHN server reports anonymized attack data back to Anomali, Inc. (formerly	
known as ThreatStream). If you are interested in viewing this data, get details	
in the	
[wiki](https://github.com/Pwnlandia/mhn/wiki/Getting-Access-to-the-MHN-Community-Data).	
This data reporting can be disabled by running the following command from the	
MHN server after completing the initial installation steps outlined above:	
`/opt/mhn/scripts/disable_collector.sh`	


## Support or Contact
MHN is an open source project that relies on community involvement. Please check out our troubleshooting guide on the wiki. We will also lend a
hand, if needed. Find us at: <modern-honey-network@googlegroups.com>.

### Credit and Thanks
MHN was originally created by Anomali, Inc.

MHN leverages and extends upon several awesome projects by the Honeynet project.
Please show them your support by way of donation.

## LICENSE

Modern Honeypot Network

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
