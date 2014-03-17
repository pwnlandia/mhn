Modern Honey Net Framework
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


### INSTALLING SERVER

1. Clone the repository and move the server directory:

   `git clone https://github.com/threatstream/MHN.git && cd MHN/server`

2. Install system requirements:
   - C Compiler
   - Python dev libraries
   - Redis server

   Example in Debia/Ubuntu Linux:

   `sudo apt-get install build-essential python-dev redis-server`

3. Install Python dependencies listed on `MHN/server/requirements.txt`, using `virtualenv` and `pip` is recommended:

   `pip install -r requirements.txt`


### RUNNING SERVER


1. With `MHN/server/` as current working directory, run:

   `python manage.py run`

    The script will try to import `config.py`, if this fails, it will asume that this is the first time the server is being ran and will assist you in creating a proper `config.py` for your local installation by asking the following information:

    * `Do you wish to run in Debug mode?: y/n`: Answer `y` or `no` accordingly.
    * `Superuser email`: Email address for default user.
    * `Superuser password`: Password for default user.
    * `Server base url ['http://127.0.0.1:8080']`: Server's reachable HTTP address including port.
    * `Path for log file ['mhn.log']`: A path where the application logs will be located. Defaults to `mhn.log`.

    After this step, the server should run using Flask's built in HTTP server, using address `0.0.0.0`. This setup is not recommended for a production environment.

2. The MHN server uses celery tasks to download rules periodically, in order for this to work, the following commands must be ran and kept alive. Using a different console window is recommended:

    `celery -A mhn.tasks --config=config beat`

    `celery -A mhn.tasks --config=config worker`

   Append `&` to the commands in order for them to run in the background.
