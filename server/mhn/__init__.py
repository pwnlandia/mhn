from flask import Flask

mhn = Flask(__name__)


# Registering blueprints.
from api.views import api
mhn.register_blueprint(api)

from ui.views import ui
mhn.register_blueprint(ui)
