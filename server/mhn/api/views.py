import json
from uuid import uuid1

from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from flask import Blueprint, request, jsonify, make_response
from bson.errors import InvalidId

from mhn import db
from mhn.api import errors
from mhn.api.models import (
        Sensor, Rule, DeployScript as Script,
        DeployScript, RuleSource)
from mhn.api.decorators import deploy_auth, sensor_auth
from mhn.common.utils import error_response
from mhn.common.clio import Clio
from mhn.auth import current_user, login_required


api = Blueprint('api', __name__, url_prefix='/api')


# Endpoints for the Sensor resource.
@api.route('/sensor/', methods=['POST'])
@deploy_auth
def create_sensor():
    missing = Sensor.check_required(request.json)
    if missing:
        return error_response(
                errors.API_FIELDS_MISSING.format(missing), 400)
    else:
        sensor = Sensor(**request.json)
        sensor.uuid = str(uuid1())
        sensor.ip = request.remote_addr
        Clio().authkey.new(**sensor.new_auth_dict()).post()
        try:
            db.session.add(sensor)
            db.session.commit()
        except IntegrityError:
            return error_response(
                    errors.API_SENSOR_EXISTS.format(request.json['name']), 400)
        else:
            return jsonify(sensor.to_dict())


@api.route('/sensor/<uuid>/', methods=['PUT'])
def update_sensor(uuid):
    sensor = Sensor.query.filter_by(uuid=uuid).first_or_404()
    for field in request.json.keys():
        if field in Sensor.editable_fields():
            setattr(sensor, field, request.json[field])
        elif field in Sensor.fields():
            return error_response(
                    errors.API_FIELD_NOT_EDITABLE.format(field), 400)
        else:
            return error_response(
                    errors.API_FIELD_INVALID.format(field), 400)
    else:
        try:
            db.session.commit()
        except IntegrityError:
            return error_response(
                    errors.API_SENSOR_EXISTS.format(request.json['name']), 400)
        return jsonify(sensor.to_dict())


@api.route('/sensor/<uuid>/', methods=['DELETE'])
@login_required
def delete_sensor(uuid):
    sensor = Sensor.query.filter_by(uuid=uuid).first_or_404()
    db.session.delete(sensor)
    db.session.commit()
    return jsonify({})


@api.route('/sensor/<uuid>/connect/', methods=['POST'])
@sensor_auth
def connect_sensor(uuid):
    sensor = Sensor.query.filter_by(uuid=uuid).first_or_404()
    sensor.ip = request.remote_addr
    db.session.commit()
    return jsonify(sensor.to_dict())


# Utility functions that generalize the GET
# requests of resources from Mnemosyne.
def _get_one_resource(resource, res_id):
    try:
        res = resource.get(_id=res_id)
    except InvalidId:
        res = None
    if not res:
        return error_response(errors.API_RESOURCE_NOT_FOUND, 404)
    else:
        return jsonify(res.to_dict())


def _get_query_resource(resource, query):
    return jsonify(data=[r.to_dict() for r in resource.get(**query)])
# Now let's make use these methods in the views.


@api.route('/feed/<feed_id>/', methods=['GET'])
@login_required
def get_feed(feed_id):
    return _get_one_resource(Clio().hpfeed, feed_id)


@api.route('/session/<session_id>/', methods=['GET'])
@login_required
def get_session(session_id):
    return _get_one_resource(Clio().session, session_id)


@api.route('/feed/', methods=['GET'])
@login_required
def get_feeds():
    return _get_query_resource(Clio().hpfeed, request.args.to_dict())


@api.route('/session/', methods=['GET'])
@login_required
def get_sessions():
    return _get_query_resource(Clio().session, request.args.to_dict())


@api.route('/rule/<rule_id>/', methods=['PUT'])
@login_required
def update_rule(rule_id):
    rule = Rule.query.filter_by(id=rule_id).first_or_404()
    for field in request.json.keys():
        if field in Rule.editable_fields():
            setattr(rule, field, request.json[field])
        elif field in Rule.fields():
            return error_response(
                    errors.API_FIELD_NOT_EDITABLE.format(field), 400)
        else:
            return error_response(
                    errors.API_FIELD_INVALID.format(field), 400)
    else:
        db.session.commit()
        return jsonify(rule.to_dict())


@api.route('/rule/', methods=['GET'])
@sensor_auth
def get_rules():
    # Getting active rules.
    if request.args.get('plaintext') in ['1', 'true']:
        # Requested rendered rules in plaintext.
        resp = make_response(Rule.renderall())
        resp.headers['Content-Disposition'] = "attachment; filename=mhn.rules"
        return resp
    else:
        # Responding with active rules.
        rules = Rule.query.filter_by(is_active=True).\
                    group_by(Rule.sid).\
                    having(func.max(Rule.rev))
        resp = make_response(json.dumps([ru.to_dict() for ru in rules]))
        resp.headers['Content-Type'] = "application/json"
        return resp


@api.route('/rulesources/', methods=['POST'])
@login_required
def create_rule_source():
    missing = RuleSource.check_required(request.json)
    if missing:
        return error_response(
                errors.API_FIELDS_MISSING.format(missing), 400)
    else:
        rsource = RuleSource(**request.json)
        try:
            db.session.add(rsource)
            db.session.commit()
        except IntegrityError:
            return error_response(
                    errors.API_SOURCE_EXISTS.format(request.json['uri']), 400)
        else:
            return jsonify(rsource.to_dict())


@api.route('/rulesources/<rs_id>/', methods=['DELETE'])
@login_required
def delete_rule_source(rs_id):
    source = RuleSource.query.filter_by(id=rs_id).first_or_404()
    db.session.delete(source)
    db.session.commit()
    return jsonify({})


@api.route('/script/', methods=['POST'])
@login_required
def create_script():
    missing = Script.check_required(request.json)
    if missing:
        return error_response(
                errors.API_FIELDS_MISSING.format(missing), 400)
    else:
        script = Script(**request.json)
        script.user = current_user
        db.session.add(script)
        db.session.commit()
        return jsonify(script.to_dict())


@api.route('/script/', methods=['PUT', 'PATCH'])
@login_required
def update_script():
    script = Script.query.get(request.json.get('id'))
    script.user = current_user
    for editable in Script.editable_fields():
        if editable in request.json:
            setattr(script, editable, request.json[editable])
    db.session.add(script)
    db.session.commit()
    return jsonify(script.to_dict())


@api.route('/script/', methods=['GET'])
def get_script():
    if request.args.get('script_id'):
        script = DeployScript.query.get(request.args.get('script_id'))
    else:
        script = DeployScript.query.order_by(DeployScript.date.desc()).first()
    if request.args.get('text') in ['1', 'true']:
        resp = make_response(script.script)
        resp.headers['Content-Disposition'] = "attachment; filename=deploy.sh"
        return resp
    else:
        return jsonify(script.to_dict())
