from dateutil.parser import parse as parse_date
from flask import Blueprint, render_template, request
from sqlalchemy import desc, func

from mhn.api.models import Attack, Sensor, Rule
from mhn.auth import login_required
from mhn import db


ui = Blueprint('ui', __name__, url_prefix='/ui')


@ui.route('/login/', methods=['GET'])
def login_user():
    return render_template('ui/login.html')


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
                           sensors=Sensor.query, **request.args.to_dict())


@ui.route('/rules/', methods=['GET'])
@login_required
def get_rules():
    rules = db.session.query(Rule, func.count(Rule.rev).label('nrevs')).\
               group_by(Rule.sid).\
               order_by(desc(Rule.date))
    return render_template('ui/rules.html', rules=rules)


@ui.route('/sensors/', methods=['GET'])
@login_required
def get_sensors():
    return render_template('ui/sensors.html',
                           sensors=Sensor.query)


@ui.route('/add-sensor/', methods=['GET'])
@login_required
def add_sensor():
    return render_template('ui/add-sensor.html')
