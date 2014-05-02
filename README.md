Modern Honey Network
==========================

Multi-snort and honeypot sensor management, uses a network of VMs, small footprint SNORT installations, stealthy dionaeas, and a centralized server for management.

### HONEYPOT

Deployed sensors with intrusion detection software installed: SNORT, Dionaea. Uses the client application to take information from the IDS and communicate with the Management Server using the HTTP API.

The honeypot reads the IDS output to generate attack reports and communicates them to the server using the client application.


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

1. Clone the repository and move the server directory:

   `git clone https://github.com/threatstream/MHN.git && cd MHN/server`

2. Install system requirements:
   - C Compiler
   - Python dev libraries
   - Redis server

   Example in Debia/Ubuntu Linux:

   `sudo apt-get install build-essential python-dev redis-server python-pip`

3. Install Python dependencies listed on `MHN/server/requirements.txt`, using `virtualenv` and `pip` is recommended:

   `pip install -r requirements.txt`


### RUNNING SERVER


1. With `MHN/server/` as current working directory, run:

   `python manage.py run`

    The script will try to import `config.py`, if this fails, it will asume that this is the first time the server is being ran and will assist you in creating a proper `config.py` for your local installation by asking the following information:

    * `Do you wish to run in Debug mode?: y/n`: Answer `y` or `no` accordingly.
    * `Superuser email`: Email address for default user.
    * `Superuser password`: Password for default user.
    * `Server base url ['http://127.0.0.1:8080']`: Server's reachable HTTP address including port. A suggested address is presented inside the brackets, if that address is incorrect, type in the correct address that clients will use to reach the server.
    * `Path for log file ['mhn.log']`: A path where the application logs will be located. Defaults to `mhn.log`.

    After this step, the server should run using Flask's built in HTTP server, using address `0.0.0.0`. This setup is not recommended for a production environment.

    Note that this command also runs two celery commands internally as the MHN server uses celery tasks to download rules periodically.

    `celery -A mhn.tasks --config=config beat`

    `celery -A mhn.tasks --config=config worker`

    `&` is appended to the commands in order for them to run in the background.


### ADVANCED SETUP

MHN auto configuration sets up SQLite as database engine for the server, but you can set up your server to use a different database engine:

#### MySQL

`SQLALCHEMY_DATABASE_URI = 'mysql://username:password@localhost/databasename'`

#### PostgreSQL

`SQLALCHEMY_DATABASE_URI = 'postgresql://username:password@localhost/databasename'`

For more information visit: https://github.com/mitsuhiko/flask-sqlalchemy.

### Production deploy with NGINX and UWSGI

The following instructions where tested for Ubuntu 12.04, if you are using a different distro or UNIX platform, all you need to do is find the proper packages for your system and everything else should work the same.

##### Installing dependencies

Same requirements from RUNNING SERVER section:

`sudo apt-get install build-essential python-dev redis-server python-pip`

And some additional pacakges:

`sudo apt-get install nginx`

`sudo apt-get install supervisor`

##### Preparing the Python application

Clone the repository and install the requirements on a fresh python virtualenv (recommended). 

`git clone https://github.com/threatstream/MHN.git`

`sudo pip install virtualenv`

`virtualenv mhnenv`

`source mhnenv/bin/activate`

`cd MHN/server`

`pip install -r requirements.txt`

Create link to the application and virtualenv folders in `/opt/`:

`sudo mdkir /opt/MHN`

`cd /opt/MHN`

`sudo ln -s ~/MHN/server server`

`sudo ln -s ~/mhnenv mhnenv`



##### NGINX configuration

Edit the file `/etc/nginx/sites-available/default` to include the application:


```
server {
    listen       80;
    server_name  _;
    location / { try_files $uri @mhnserver; }
    root /opt/MHN/server;

    location @mhnserver {
      include uwsgi_params;
      uwsgi_pass unix:/tmp/uwsgi.sock;
    }

    location  /static {
      alias /opt/MHN/server/mhn/static;
    }
}
```

To enable our new site let's create a link of `sites-available/default` in `sites-enabled/default`:

`ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default`


##### UWSGI configuration

UWSGI doesn't need much configuration to work, but it is recommmended to use `supervisor` process manager to take care of monitoring the process; we will also be using `supervisor` to run the `celery` worker and beat process.

Once `supervisor` is installed, edit `/etc/supervisor/supervisord.conf` to add (append) the following commands:

```
[program:mhn-uwsgi]
command=/opt/MHN/mhnenv/bin/uwsgi -s /tmp/uwsgi.sock -w mhn:mhn -H /opt/MHN/mhnenv --chmod-socket=666
directory=/opt/MHN/server
stdout_logfile=/var/log/uwsgi/mhn.log
stderr_logfile=/var/log/uwsgi/mhn.log
autostart=true
autorestart=true
startsecs=10

[program:celery-worker]
command=/opt/MHN/mhnenv/bin/celery worker -A mhn.tasks --loglevel=INFO
directory=/opt/MHN/server
stdout_logfile=/opt/MHN/server/worker.log
stderr_logfile=/opt/MHN/server/worker.log
autostart=true
autorestart=true
startsecs=10

[program:celery-beat]
command=/opt/MHN/mhnenv/bin/celery beat -A mhn.tasks --loglevel=INFO
directory=/opt/MHN/server
stdout_logfile=/opt/MHN/server/worker.log
stderr_logfile=/opt/MHN/server/worker.log
autostart=true
autorestart=true
startsecs=10
```

Then we need to create the folder where `supervisor` is going to store the `uwsgi` output:

`sudo mkdir /var/log/uwsgi`

Finally let's make sure the processes have the correct permissions to the application sources:

`cd ~/MHN/server`

`sudo chown www-data:www-data * -R`

Reboot your computer and the server you should have an MHN server running on the box:

`sudo reboot`


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
