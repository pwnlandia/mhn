from flask import current_app


def config_ctx():
    """
    Inserts some settings to be used in templates.
    """
    settings = {
        'server_url': current_app.config['SERVER_BASE_URL'],
        'deploy_key': current_app.config['DEPLOY_KEY']
    }
    return dict(settings=settings)
