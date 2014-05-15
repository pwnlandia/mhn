from flask import current_app


def config_ctx():
    """
    Inserts some settings to be used in templates.
    """
    settings = {
        'server_url': current_app.config['SERVER_BASE_URL'],
        'honeymap_url': current_app.config['HONEYMAP_URL'],
        'deploy_key': current_app.config['DEPLOY_KEY'],
        'supported_honeypots': current_app.config['HONEYPOT_CHANNELS'].keys()
    }
    return dict(settings=settings)
