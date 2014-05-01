from datetime import datetime, timedelta

from dateutil.parser import parse as parse_date
from flask import (
        Blueprint, render_template, request, url_for,
        redirect, g)
from flask_security import logout_user as logout
from sqlalchemy import desc, func

from mhn.api.models import (
        Attack, Sensor, Rule, DeployScript as Script,
        RuleSource)
from mhn.auth import login_required, current_user
from mhn.auth.models import User, PasswdReset
from mhn import db, mhn
from mhn.common.utils import paginate


ui = Blueprint('ui', __name__, url_prefix='/ui')


@ui.before_request
def check_page():
    """
    Cleans up any query parameter that is used
    to build pagination.
    """
    try:
        page = int(request.args.get('page', 1))
    except ValueError:
        page = 1
    g.page = page


@ui.route('/login/', methods=['GET'])
def login_user():
    if current_user.is_authenticated():
        return redirect(url_for('ui.dashboard'))
    return render_template('security/login_user.html')


@mhn.route('/')
@ui.route('/dashboard/', methods=['GET'])
@login_required
def dashboard():
    # Number of attacks in the last 24 hours.
    attackcount = Attack.query.filter(
            Attack.date >= datetime.utcnow() - timedelta(hours=24)).count()
    # TOP 5 attacker ips.
    worst_ips = db.session.query(Attack.source_ip.label('ip'),
                                 func.count(Attack.source_ip).label('count')).\
                           group_by(Attack.source_ip).\
                           order_by(desc('count')).\
                           limit(5)
    # TOP 5 more frequent attack signatures.
    freq_signs = db.session.query(Attack.classification.label('classification'),
                                  Attack.signature.label('signature'),
                                  func.count(Attack.classification).label('count')).\
                            filter(Attack.classification != '').\
                            group_by(Attack.classification).\
                            order_by(desc('count')).\
                            limit(5)
    # TOP 5 attacked ports.)
    top_ports = db.session.query(Attack.destination_port.label('port'),
                                  func.count(Attack.destination_port).label('count')).\
                            group_by(Attack.destination_port).\
                            order_by(desc('count')).\
                            limit(5)


    return render_template('ui/dashboard.html',
                           attackcount=attackcount,
                           worst_ips=worst_ips,
                           freq_signs=freq_signs,
                           top_ports=top_ports)


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
    attacks = paginate(attacks)
    return render_template('ui/attacks.html', attacks=attacks,
                           sensors=Sensor.query, view='ui.get_attacks',
                           **request.args.to_dict())


@ui.route('/rules/', methods=['GET'])
@login_required
def get_rules():
    rules = db.session.query(Rule, func.count(Rule.rev).label('nrevs')).\
               group_by(Rule.sid).\
               order_by(desc(Rule.date))
    rules = paginate(rules)
    return render_template('ui/rules.html', rules=rules, view='ui.get_rules')


@ui.route('/rule-sources/', methods=['GET'])
@login_required
def rule_sources_mgmt():
    sources = RuleSource.query
    return render_template('ui/rule_sources_mgmt.html', sources=sources)


@ui.route('/sensors/', methods=['GET'])
@login_required
def get_sensors():
    # The following uses fancy SQLAlchemy subqueries to query
    # Sensors ordered by the number of attacks.
    # 1. Creating subquery with attacks count per sensor.
    # 2. Querying sensors outer-joining the subquery made beforehand,
    #    and ordering by its attack_count column.
    stmt = db.session.query(Attack.sensor_id,
                            func.count('*').label('attack_count')).\
                      group_by(Attack.sensor_id).subquery()
    sensors = db.session.query(Sensor).\
                         outerjoin(stmt, Sensor.id==stmt.c.sensor_id).\
                         order_by(desc(stmt.c.attack_count))
    sensors = paginate(sensors)
    return render_template('ui/sensors.html', sensors=sensors,
                           view='ui.get_sensors')


@ui.route('/add-sensor/', methods=['GET'])
@login_required
def add_sensor():
    return render_template('ui/add-sensor.html')


@ui.route('/manage-deploy/', methods=['GET'])
@login_required
def deploy_mgmt():
    return render_template('ui/script.html',
                           script=Script.query.order_by(Script.date.desc()).first())


@ui.route('/add-user/', methods=['GET'])
@login_required
def settings():
    return render_template(
            'ui/settings.html', users=User.query.filter_by(active=True))


@ui.route('/forgot-password/<hashstr>/', methods=['GET'])
def forgot_passwd(hashstr):
    logout()
    user = PasswdReset.query.filter_by(hashstr=hashstr).first().user
    return render_template('ui/reset-password.html', reset_user=user,
                           hashstr=hashstr)


@ui.route('/reset-password/', methods=['GET'])
def reset_passwd():
    return render_template('ui/reset-request.html')
