from flask.ext.security import SQLAlchemyUserDatastore, login_required
from flask_security.core import current_user


def get_datastore():
    from mhn.auth import user_datastore
    return user_datastore
