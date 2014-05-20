import requests
from flask import current_app as app

from mhn.ui import constants
from config import MHN_SERVER_HOME
import os

def get_flag_ip(ipaddr):
    """
    Returns an static address where the flag is located.
    Defaults to static immge: '/static/img/unknown.png'
    """
    flag_path = '/static/img/flags-iso/shiny/64/{}.png'
    geo_api = 'https://geospray.threatstream.com/ip/{}'
    try:
        # Using threatstream's geospray API to get
        # the country code for this IP address.
        r = requests.get(geo_api.format(ipaddr))
        ccode = r.json()['countryCode']
    except ValueError:
        # Response wasn't json, use default flag.
        app.logger.warning('Failed to get country code for: "{}"'.format(ipaddr))
        return constants.DEFAULT_FLAG_URL
    except KeyError:
        # Response with unexpected format, using default.
        app.logger.warning(
                'Unexpected response for "{}": {}'.format(r.url, r.json()))
        return constants.DEFAULT_FLAG_URL
    else:
        # Constructs the flag source using country code
        flag = flag_path.format(ccode.upper())
        if os.path.exists(MHN_SERVER_HOME +"/mhn"+flag):
            return flag
        else:
            return constants.DEFAULT_FLAG_URL
