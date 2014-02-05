from functools import wraps

from flask import request, current_app

from mhn.api import errors
from mhn.common.utils import error_response
from mhn.auth import current_user


def deploy_auth(view):
    """
    Authenticates the view, allowing access if user
    is authenticated or if posted deploy key is correct.
    """
    @wraps(view)
    def wrapped_view(*args, **kwargs):
        if current_user and current_user.is_authenticated():
            return view(*args, **kwargs)
        elif 'deploy_key' in request.json:
            server_key = current_app.config['DEPLOY_KEY']
            passed_key = request.json['deploy_key']
            if server_key == passed_key:
                return view(*args, **kwargs)
        return error_response(errors.API_NOT_AUTHORIZED, 401)
    return wrapped_view
