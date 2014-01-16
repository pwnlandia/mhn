from dateutil.parser import parse as parse_date
from flask import Blueprint, render_template, request
from sqlalchemy import desc

from mhn.api.models import Attack
from mhn.api.models import Sensor
from mhn.auth import login_required


ui = Blueprint('ui', __name__, url_prefix='/ui')


@ui.route('/attacks/', methods=['GET'])
@login_required
def get_attacks():
    attacks = Attack.query
    date = request.args.get('date')
    sensor = request.args.get('sensor')
    if date:
        try:
            date = parse_date(date)
            attacks = attacks.filter(Attack.date >= date)
        except TypeError:
            pass
    if sensor:
        attacks = attacks.join(Sensor).filter(Sensor.uuid == sensor)
    attacks = attacks.order_by(desc(Attack.date))
    return render_template('ui/attacks.html', attacks=attacks,
                           sensors=Sensor.query.all(), **request.args.to_dict())
