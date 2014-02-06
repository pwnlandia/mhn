from functools import wraps

from flask import request, current_app

from mhn.api import errors
from mhn.api.models import Sensor
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


def sensor_auth(view):
    """
    Authenticates the view, allowing access if user
    is authenticated or if requesting from a sensor.
    """
    @wraps(view)
    def wrapped_view(*args, **kwargs):
        if current_user and current_user.is_authenticated():
            return view(*args, **kwargs)
        elif request.authorization:
            auth = request.authorization
            if auth and auth.get('username') == auth.get('password') and\
               Sensor.query.filter_by(uuid=auth.get('username')).count() == 1:
                print 'yes'
                return view(*args, **kwargs)
        return error_response(errors.API_NOT_AUTHORIZED, 401)
    return wrapped_view
