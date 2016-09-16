"""
This is a helper script meant to generate a
working config.py file from the config template.
"""

from getpass import getpass
import json
import os.path
from random import choice
import string
import sys
from urllib2 import urlopen

import argparse


el = string.ascii_letters + string.digits
rand_str = lambda n: ''.join(choice(el) for _ in range(n))


def generate_config():
    # Check if config file already exists
    if os.path.isfile('config.py'):
        print('config.py already exists')
        sys.exit()

    pub_ip = json.load(urlopen('http://httpbin.org/ip'))['origin']
    default_base_url = 'http://{}'.format(pub_ip)
    default_honeymap_url = '{}:3000'.format(default_base_url)
    default_log_path = '/var/log/mhn/mhn.log'
    localconfig = {}
    localconfig['SECRET_KEY'] = rand_str(32)
    localconfig['DEPLOY_KEY'] = rand_str(8)

    is_unattended = False

     # Get and parse args for command unattended install
    parser_description = 'This is a help script to generate a working config.py file from the config template.'
    parser = argparse.ArgumentParser(description=parser_description)

    subparsers = parser.add_subparsers(help='commands')

    parser_generate = subparsers.add_parser('generate', help='Generate a config.py and prompt for options')
    parser_generate.set_defaults(which='generate')

    parser_unatt = subparsers.add_parser('unattended', help='Unattended install')
    parser_unatt.set_defaults(which='unattended')
    parser_unatt.add_argument('-e', '--email', type=str, required=True,
                              help='Superuser email address')
    parser_unatt.add_argument('-p', '--password', type=str, required=True,
                              help='Superuser password')
    parser_unatt.add_argument('-b', '--base_url', type=str, default=default_base_url,
                              help='Server base url')
    parser_unatt.add_argument('-y', '--honeymap_url', type=str, default=default_honeymap_url,
                              help='Honeymap url')
    parser_unatt.add_argument('-m', '--mail_server', type=str, default='localhost',
                              help='Mail server address')
    parser_unatt.add_argument('-s', '--mail_port', type=int, default=25,
                              help='Mail server port')
    parser_unatt.add_argument('--mail_tls', action='store_true',
                              help='Use TLS for mail')
    parser_unatt.add_argument('--mail_ssl', action='store_true',
                              help='Use SSL for mail')
    parser_unatt.add_argument('--mail_user', type=str, default='',
                              help='Mail username')
    parser_unatt.add_argument('--mail_pass', type=str, default='',
                              help='Mail password')
    parser_unatt.add_argument('--mail_sender', type=str, default='',
                              help='Mail sender')
    parser_unatt.add_argument('-l', '--log_file_path', type=str, default=default_log_path,
                              help='Log file path')
    parser_unatt.add_argument('-d', '--debug', action='store_true',
                              help='Run in debug mode')

    if (len(sys.argv) < 2):
        args = parser.parse_args(['generate'])
    else:
        args = parser.parse_args(sys.argv[1:])

    # check for unattended install
    if args.which is 'unattended':
        is_unattended = True

    if is_unattended:
        # Collect values from arguments
        debug = args.debug
        email = args.email
        password = args.password
        server_base_url= args.base_url
        honeymap_url = args.honeymap_url
        mail_server = args.mail_server
        mail_port = args.mail_port
        mail_tls = args.mail_tls
        mail_ssl = args.mail_ssl
        mail_username = args.mail_user
        mail_password = args.mail_pass
        default_mail_sender = args.mail_sender
        log_file_path = args.log_file_path
    else:
        # Collect values from user
        debug = raw_input('Do you wish to run in Debug mode?: y/n ')
        while debug not in ['y', 'n']:
            debug = raw_input('Please y or n ')
        debug = True if debug == 'y' else False

        email = raw_input('Superuser email: ')
        while '@' not in email:
            email = raw_input('Superuser email (must be valid): ')

        while True:
            password = getpass('Superuser password: ')
            while not password:
                password = getpass('Superuser password (cannot be blank): ')

            password2 = getpass('Superuser password: (again): ')
            while not password2:
                password2 = getpass('Superuser password (again; cannot be blank): ')

            if password == password2:
                break
            else:
                print "Passwords did not match. Try again"

        server_base_url = raw_input('Server base url ["{}"]: '.format(default_base_url))
        if server_base_url.endswith('/'):
            server_base_url = server_base_url[:-1]

        default_honeymap_url = '{}:3000'.format(server_base_url)
        honeymap_url = raw_input('Honeymap url ["{}"]: '.format(default_honeymap_url))
        if honeymap_url.endswith('/'):
            honeymap_url = honeymap_url[:-1]

        mail_server = raw_input('Mail server address ["localhost"]: ')
        mail_port = raw_input('Mail server port [25]: ')

        mail_tls = raw_input('Use TLS for email?: y/n ')
        while mail_tls not in ['y', 'n']:
            mail_tls = raw_input('Please y or n ')

        mail_ssl = raw_input('Use SSL for email?: y/n ')
        while mail_ssl not in ['y', 'n']:
            mail_ssl = raw_input('Please y or n ')

        mail_username = raw_input('Mail server username [""]: ')
        mail_password = getpass('Mail server password [""]: ')

        default_mail_sender = raw_input('Mail default sender [""]: ')

        log_file_path = raw_input('Path for log file ["{}"]: '.format(default_log_path))

    server_base_url = server_base_url if server_base_url.strip() else default_base_url
    honeymap_url = honeymap_url if honeymap_url.strip() else default_honeymap_url
    log_file_path = log_file_path if log_file_path else default_log_path

    localconfig['DEBUG'] = debug
    localconfig['SUPERUSER_EMAIL'] = email
    localconfig['SUPERUSER_PASSWORD'] = password
    localconfig['SERVER_BASE_URL'] = server_base_url
    localconfig['HONEYMAP_URL'] = honeymap_url
    localconfig['MAIL_SERVER'] = mail_server if mail_server else "localhost"
    localconfig['MAIL_PORT'] = mail_port if mail_port else 25
    localconfig['MAIL_USE_TLS'] = 'y' == mail_tls
    localconfig['MAIL_USE_SSL'] = 'y' == mail_ssl
    localconfig['MAIL_USERNAME'] = mail_username if mail_username else ''
    localconfig['MAIL_PASSWORD'] = mail_password if mail_password else ''
    localconfig['DEFAULT_MAIL_SENDER'] = default_mail_sender if default_mail_sender else ""
    localconfig['LOG_FILE_PATH'] = log_file_path

    with open('config.py.template', 'r') as templfile,\
         open('config.py', 'w') as confile:
        templ = templfile.read()
        for key, setting in localconfig.iteritems():
            templ = templ.replace('{{' + key + '}}', str(setting))
        confile.write(templ)


if __name__ == '__main__':
    generate_config()
