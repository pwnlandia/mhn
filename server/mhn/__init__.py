from flask import Flask
from flask.ext.sqlalchemy import SQLAlchemy
from flask.ext.security import Security, SQLAlchemyUserDatastore
from flask.ext.security.utils import encrypt_password as encrypt


db = SQLAlchemy()

# After defining `db`, import auth models due to
# circular dependency.
from mhn.auth.models import User, Role
user_datastore = SQLAlchemyUserDatastore(db, User, Role)


def create_app():
    mhn = Flask(__name__)
    mhn.config.from_object('config')

    # Registering app on db instance.
    db.init_app(mhn)

    # Setup flask-security for auth.
    Security(mhn, user_datastore)

    # Registering blueprints.
    from mhn.api.views import api
    mhn.register_blueprint(api)

    from mhn.ui.views import ui
    mhn.register_blueprint(ui)

    from mhn.auth.views import auth
    mhn.register_blueprint(auth)

    return mhn


def create_clean_db():
    """
    Use from a python shell to create a fresh database.
    """
    mhn = create_app()
    mhn.test_request_context().push()
    db.create_all()
    superuser = user_datastore.create_user(
            email=mhn.config.get('SUPERUSER_EMAIL'),
            password=encrypt(mhn.config.get('SUPERUSER_PASSWORD')))
    adminrole = user_datastore.create_role(name='admin', description='')
    user_datastore.add_role_to_user(superuser, adminrole)
    db.session.commit()
