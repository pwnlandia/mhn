from datetime import datetime, timedelta

from flask import (
        Blueprint, render_template, request, url_for,
        redirect, g)
from flask_security import logout_user as logout
from sqlalchemy import desc, func

from mhn.api.models import (
        Sensor, Rule, DeployScript as Script,
        RuleSource)
from mhn.auth import login_required, current_user
from mhn.auth.models import User, PasswdReset
from mhn import db, mhn
from mhn.common.utils import (
        paginate_options, alchemy_pages, mongo_pages)
from mhn.common.clio import Clio
from mhn.constants import PAGE_SIZE


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
    clio = Clio()
    # Number of attacks in the last 24 hours.
    attackcount = clio.session.count(
             timestamp_lte=datetime.utcnow() - timedelta(hours=24))
    # TOP 5 attacker ips.
    top_attackers = clio.session.top_attackers(top=5)
    # TOP 5 attacked ports
    top_ports = clio.session.top_targeted_ports(top=5)

    return render_template('ui/dashboard.html',
                           attackcount=attackcount,
                           top_attackers=top_attackers,
                           top_ports=top_ports)


@ui.route('/attacks/', methods=['GET'])
@login_required
def get_attacks():
    clio = Clio()
    options = paginate_options()
    options['order_by'] = '-timestamp'
    total = clio.session.count(**request.args.to_dict())
    sessions = clio.session.get(
            options=options, **request.args.to_dict())
    sessions = mongo_pages(sessions, total)
    return render_template('ui/attacks.html', attacks=sessions,
                           sensors=Sensor.query, view='ui.get_attacks',
                           **request.args.to_dict())


@ui.route('/rules/', methods=['GET'])
@login_required
def get_rules():
    rules = db.session.query(Rule, func.count(Rule.rev).label('nrevs')).\
               group_by(Rule.sid).\
               order_by(desc(Rule.date))
    rules = alchemy_pages(rules)
    return render_template('ui/rules.html', rules=rules, view='ui.get_rules')


@ui.route('/rule-sources/', methods=['GET'])
@login_required
def rule_sources_mgmt():
    sources = RuleSource.query
    return render_template('ui/rule_sources_mgmt.html', sources=sources)


@ui.route('/sensors/', methods=['GET'])
@login_required
def get_sensors():
    sensors = db.session.query(Sensor)
    sensors = sorted(
            sensors, key=lambda s: s.attacks_count, reverse=True)
    # Paginating the list.
    sensors = sensors[(g.page - 1) * PAGE_SIZE:PAGE_SIZE]
    # Using mongo_pages because it expects paginated iterables.
    sensors = mongo_pages(sensors, len(sensors))
    return render_template('ui/sensors.html', sensors=sensors,
                           view='ui.get_sensors')


@ui.route('/add-sensor/', methods=['GET'])
@login_required
def add_sensor():
    return render_template('ui/add-sensor.html')


@ui.route('/manage-deploy/', methods=['GET'])
@login_required
def deploy_mgmt():
    script_id = request.args.get('script_id')
    if not script_id or script_id == '0':
        script = Script(name='', notes='', script='')
    else:
        script = Script.query.get(script_id)
    return render_template(
            'ui/script.html', scripts=Script.query.order_by(Script.date.desc()),
            script=script)


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
