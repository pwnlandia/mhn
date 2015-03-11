from flask import (Blueprint, render_template)
from mhn.auth import login_required

hello_addon = Blueprint('hello_addon', __name__, template_folder='templates/', url_prefix='/addons/hello_addon')

@hello_addon.route('/home/', methods=['GET'])
@login_required
def home():
    return render_template('hello_world.html')

__author__ = 'mercolino'