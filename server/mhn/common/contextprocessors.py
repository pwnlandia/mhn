from flask import current_app

import mhn.common.utils as utils

def config_ctx():
    """
    Inserts some settings to be used in templates.
    """

    settings = {
        'server_url': current_app.config['SERVER_BASE_URL'],
        'honeymap_url': current_app.config['HONEYMAP_URL'],
        'deploy_key': current_app.config['DEPLOY_KEY'],
        'supported_honeypots': current_app.config['HONEYPOT_CHANNELS'].keys(),
        'add_ons_enabled': current_app.config['ADD_ONS']
    }
    if current_app.config['ADD_ONS']:
        settings['add_ons'] = utils.get_addons()
    return dict(settings=settings)
