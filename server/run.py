import config
from mhn import create_app


create_app().run(debug=config.DEBUG)
