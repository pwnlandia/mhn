MHN
===

Modern Honey Net Framework


Build a multi-snort and honeypot management sensor

Each VM will need to run honeypot servers and snort within 1G of memory.

Snort tips for small memory footprint:
http://www.instructables.com/id/Raspberry-Pi-Firewall-and-Intrusion-Detection-Syst/step13/SNORT/

Make Dionaea stealthy
http://blog.sbarbeau.fr/2012/06/make-dionaea-stealthier-for-fun-and-no.html

Possibilities for Snort Sensor management
https://github.com/davhenriksen/bringhomethebacon
https://bitbucket.org/onelson/django-clu
https://github.com/stianja/SnortManager

Honeypot setup Script:
https://github.com/andrewmichaelsmith/honeypot-setup-script

Snort setup Script:
https://github.com/da667/Autosnort

Project definition:
1. bash script which you supply a management server IP/DNS and password to the command line, ie:

wget http://mgmt.srvr.com/deploy/script.bash -O /tmp/deploy.bash && bash /tmp/deploy.bash mgmt.srvr.com mypassword123

connects to http://mgmt.srvr.com/register/, registers the IP, hostname and creates a new sensor ID.

Snort rules downloaded from http://mgmt.srvr.com/rules/download

all honeypot and IDS logs sent to > http://mgmt.srver.com/log

show a list of new attacks http://mgmt.srver.com/dashboard

manage rules (enable, disable, download) http://mgmt.srvr.com/rules/

