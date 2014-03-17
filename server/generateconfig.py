"""
This is a helper script meant to generate a
working config.py file from the config template.
"""

import string
from random import choice
from getpass import getpass
from socket import gethostbyname, gethostname


el = string.ascii_letters + string.digits
rand_str = lambda n: ''.join(choice(el) for _ in range(n))
default_base_url = 'http://{}:8080'.format(gethostbyname(gethostname()))
default_log_path = 'mhn.log'


def generate_config():
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
    log_file_path = raw_input('Path for log file ["{}"]: '.format(default_log_path))
    log_file_path = log_file_path if log_file_path else default_log_path
    localconfig['LOG_FILE_PATH'] = log_file_path
    with open('config.py.template', 'r') as templfile,\
         open('config.py', 'w') as confile:
        templ = templfile.read()
        for key, setting in localconfig.iteritems():
            if isinstance(setting, bool):
                setting = 'True' if setting else 'False'
            templ = templ.replace('{{' + key + '}}', setting)
        confile.write(templ)


if __name__ == '__main__':
    generate_config()
