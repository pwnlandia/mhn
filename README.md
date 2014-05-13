Modern Honey Network
==========================

Multi-snort and honeypot sensor management, uses a network of VMs, small footprint SNORT installations, stealthy dionaeas, and a centralized server for management.

### HONEYPOT

Deployed sensors with intrusion detection software installed: SNORT, Conpot, and Dionaea. 

### MANAGEMENT SERVER

Flask application that exposes an HTTP API that honeypots can use to:
- Download a deploy script
- Connect and register
- Download snort rules
- Send intrusion detection logs

It also allows systems administrators to:
- View a list of new attacks
- Manage snort rules: enable, disable, download


### INSTALLING SERVER (tested Ubuntu 12.0.4.3 x86_64)
    
    $ cd /opt/
    $ git clone https://github.com/threatstream/MHN.git
    $ cd MHN/scripts/
    $ sudo ./install_hpfeeds.sh
    $ sudo ./install_mnemosyne.sh
    $ sudo ./install_mhnserver.sh
    $ sudo ./install_honeymap.sh  #optional

### Configuration

Prior to running MHN, you need to configure it.

    $ cd /opt/MHN/server
    $ python manage.py shell
    It seems like this is the first time running the server.
    First let us generate a proper configuration file.
    Do you wish to run in Debug mode?: y/n n
    Superuser email: YOUR_EMAIL@YOURSITE.COM
    Superuser password: ************
    Server base url ["http://1.2.3.4:8080"]: 
    Mail server address ["localhost"]: 
    Mail server port [25]: 
    Use TLS for email?: y/n 
    Please y or n n
    Use SSL for email?: y/n n
    Mail server username [""]: 
    Mail server password [""]: 
    Mail default sender [""]: 
    Path for log file ["mhn.log"]: 
    Initializing database "sqlite:////opt/MHN/server/mhn.db".


### Running

    $ sudo /etc/init.d/nginx start
    $ sudo /etc/init.d/supervisord start
    $ sudo supervisorctl status


## LICENSE

Modern Honeypot Network

Copyright (C) 2014 - ThreatStream

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
