from flask import Flask
from flask.ext.sqlalchemy import SQLAlchemy


"""
To create the database, run the following commands
on a python shell:

from mhn import create_app
from mhn import db
mhn = create_app()
mhn.test_request_context().push()
db.create_all()

"""
db = SQLAlchemy()

def create_app():
    mhn = Flask(__name__)
    mhn.config.from_object('config')

    # Registering app on db instance.
    db.init_app(mhn)

    # Registering blueprints.
    from api.views import api
    mhn.register_blueprint(api)

    from ui.views import ui
    mhn.register_blueprint(ui)

    return mhn
