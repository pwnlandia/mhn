from flask import Flask
from flask.ext.sqlalchemy import SQLAlchemy


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
