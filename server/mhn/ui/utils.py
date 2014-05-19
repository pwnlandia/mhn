import requests
from flask import current_app as app

from mhn.ui import constants


def get_flag_ip(ipaddr):
    """
    Returns an static address where the flag is located.
    Defaults to static immge: '/static/img/unknown.png'
    """
    flag_api = 'http://geonames.org/flags/x/{}.gif'
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
        # Constructs the flag source using country code and
        # geonames.org service.
        return flag_api.format(ccode.lower())
