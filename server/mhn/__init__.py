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
    from api.views import api
    mhn.register_blueprint(api)

    from ui.views import ui
    mhn.register_blueprint(ui)

    return mhn


def create_clean_db():
    """
    Use from a python shell to create a fresh database.
    """
    mhn = create_app()
    mhn.test_request_context().push()
    db.create_all()
    user_datastore.create_user(email=mhn.config.get('SUPERUSER_EMAIL'),
                               password=encrypt(mhn.config.get('SUPERUSER_PASSWORD')))
    db.session.commit()
