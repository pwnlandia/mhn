import requests
from flask import current_app as app

from mhn.ui import constants
from config import MHN_SERVER_HOME
import os
from werkzeug.contrib.cache import SimpleCache
flag_cache = SimpleCache(threshold=1000, default_timeout=300)

import socket
import struct

def is_RFC1918_addr(ip):
    # 10.0.0.0 = 167772160
    # 172.16.0.0 = 2886729728
    # 192.168.0.0 = 3232235520
    RFC1918_net_bits = ((167772160, 8), (2886729728, 12), (3232235520, 16))

    # ip to decimal
    ip = struct.unpack("!L", socket.inet_aton(ip))[0]

    for net, mask_bits in RFC1918_net_bits:
        ip_masked = ip & (2 ** 32 - 1 << (32 - mask_bits))
        if ip_masked == net:
            return True
    return False

def get_flag_ip(ipaddr):
    if is_RFC1918_addr(ipaddr):
        return constants.DEFAULT_FLAG_URL

    flag = flag_cache.get(ipaddr)
    if not flag:
        flag = _get_flag_ip(ipaddr)
        flag_cache.set(ipaddr, flag)
    return flag

def _get_flag_ip(ipaddr):
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
    except Exception:
        app.logger.warning("Could not determine flag for ip: {}".format(ipaddr))
        return constants.DEFAULT_FLAG_URL
    else:
        # Constructs the flag source using country code
        flag = flag_path.format(ccode.upper())
        if os.path.exists(MHN_SERVER_HOME +"/mhn"+flag):
            return flag
        else:
            return constants.DEFAULT_FLAG_URL
