from flask.ext.security import login_required
from flask_security.core import current_user
from flask_security.decorators import roles_accepted


def get_datastore():
    from mhn import user_datastore
    return user_datastore
