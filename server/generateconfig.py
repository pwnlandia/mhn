"""
This is a helper script meant to generate a
working config.py file from the config template.
"""

import json
from urllib2 import urlopen
import string
from random import choice
from getpass import getpass


el = string.ascii_letters + string.digits
rand_str = lambda n: ''.join(choice(el) for _ in range(n))


def generate_config():
    pub_ip = json.load(urlopen('http://httpbin.org/ip'))['origin']
    default_base_url = 'http://{}'.format(pub_ip)
    default_honeymap_url = 'http://{}:3000'.format(pub_ip)
    default_log_path = 'mhn.log'
    localconfig = {}
    localconfig['SECRET_KEY'] = rand_str(32)
    localconfig['DEPLOY_KEY'] = rand_str(8)
    debug = raw_input('Do you wish to run in Debug mode?: y/n ')
    while debug not in ['y', 'n']:
        debug = raw_input('Please y or n ')
    localconfig['DEBUG'] = 'y' == debug
    localconfig['SUPERUSER_EMAIL'] = raw_input('Superuser email: ')
    localconfig['SUPERUSER_PASSWORD'] = getpass('Superuser password: ')
    server_base_url = raw_input('Server base url ["{}"]: '.format(default_base_url))
    if server_base_url.endswith('/'):
        server_base_url = server_base_url[:-1]
    server_base_url = server_base_url if server_base_url.strip() else default_base_url
    localconfig['SERVER_BASE_URL'] = server_base_url

    honeymap_url = raw_input('Honeymap url ["{}"]: '.format(default_honeymap_url))
    if honeymap_url.endswith('/'):
        honeymap_url = honeymap_url[:-1]
    honeymap_url = honeymap_url if honeymap_url.strip() else default_honeymap_url
    localconfig['HONEYMAP_URL'] = honeymap_url

    mail_server = raw_input('Mail server address ["localhost"]: ')
    localconfig['MAIL_SERVER'] = mail_server if mail_server else "localhost"
    mail_port = raw_input('Mail server port [25]: ')
    localconfig['MAIL_PORT'] = mail_port if mail_port else 25
    mail_tls = raw_input('Use TLS for email?: y/n ')
    while mail_tls not in ['y', 'n']:
        mail_tls = raw_input('Please y or n ')
    localconfig['MAIL_USE_TLS'] = 'y' == mail_tls
    mail_ssl = raw_input('Use SSL for email?: y/n ')
    while mail_ssl not in ['y', 'n']:
        mail_ssl = raw_input('Please y or n ')
    localconfig['MAIL_USE_SSL'] = 'y' == mail_ssl
    mail_username = raw_input('Mail server username [""]: ')
    localconfig['MAIL_USERNAME'] = mail_username if mail_username else ''
    mail_password = getpass('Mail server password [""]: ')
    localconfig['MAIL_PASSWORD'] = mail_password if mail_password else ''
    default_mail_sender = raw_input('Mail default sender [""]: ')
    localconfig['DEFAULT_MAIL_SENDER'] = default_mail_sender if default_mail_sender else ""
    log_file_path = raw_input('Path for log file ["{}"]: '.format(default_log_path))
    log_file_path = log_file_path if log_file_path else default_log_path
    localconfig['LOG_FILE_PATH'] = log_file_path
    with open('config.py.template', 'r') as templfile,\
         open('config.py', 'w') as confile:
        templ = templfile.read()
        for key, setting in localconfig.iteritems():
            templ = templ.replace('{{' + key + '}}', str(setting))
        confile.write(templ)


if __name__ == '__main__':
    generate_config()
