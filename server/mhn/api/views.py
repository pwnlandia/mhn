import json
from uuid import uuid1

from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from flask import Blueprint, request, jsonify, make_response
from dateutil.parser import parse

from mhn import db
from mhn.api import errors
from mhn.api.models import (
        Sensor, Attack, Rule, DeployScript as Script)
from mhn.common.utils import error_response
from mhn.auth import current_user


api = Blueprint('api', __name__, url_prefix='/api')

# Endpoints for the Sensor resource.
@api.route('/sensor/', methods=['POST'])
def create_sensor():
    missing = Sensor.check_required(request.json)
    if missing:
        return error_response(
                errors.API_FIELDS_MISSING.format(missing), 400)
    else:
        sensor = Sensor(**request.json)
        sensor.uuid = str(uuid1())
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


@api.route('/sensor/<uuid>/connect/', methods=['POST'])
def connect_sensor(uuid):
    sensor = Sensor.query.filter_by(uuid=uuid).first_or_404()
    sensor.ip = request.remote_addr
    db.session.commit()
    return jsonify(sensor.to_dict())


# Endpoints for the Attack resource.
@api.route('/attack/', methods=['POST'])
def create_attack():
    missing = Attack.check_required(request.json)
    if missing:
        return error_response(
                errors.API_FIELDS_MISSING.format(missing), 400)
    else:
        sensor = Sensor.query.filter_by(
                uuid=request.json.get('sensor')).first_or_404()
        attack = Attack()
        attack.source_ip = request.json.get('source_ip')
        attack.destination_ip = request.json.get('destination_ip')
        attack.destination_port = request.json.get('destination_port')
        attack.priority = request.json.get('priority')
        attack.date = parse(request.json.get('date'))
        attack.classification = request.json.get('classification')
        attack.sensor = sensor
        # Doing this before add/commit to prevent `InvalidRequestError`.
        attackdict = attack.to_dict()
        try:
            db.session.add(attack)
            db.session.commit()
        except IntegrityError:
            # Silently ignoring attack repost.
            pass
        finally:
            return jsonify(attackdict)


@api.route('/rule/<rule_id>/', methods=['PUT'])
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


@api.route('/script/', methods=['POST'])
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
