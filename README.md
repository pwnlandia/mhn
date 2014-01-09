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

Supports two kinds of users, administrator and user:
- *User*: Has read permissions to rules, attacks and maybe logs.
- *Admin*: Has read/write permissions to all the resources.
