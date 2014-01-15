from uuid import uuid1

from flask import Blueprint, request, jsonify
from dateutil.parser import parse

from mhn import db
from mhn.api import errors
from mhn.api.models import Sensor, Attack
from mhn.common.utils import error_response


api = Blueprint('api', __name__, url_prefix='/api')

# Endpoints for the Sensor resource.
@api.route('/sensor/', methods=['POST'])
def create_sensor():
    missing = Sensor.check_required(request.json)
    if missing:
        return error_response(
                errors.FIELDS_MISSING.format(missing), 400)
    else:
        sensor = Sensor(**request.json)
        sensor.uuid = str(uuid1())
        db.session.add(sensor)
        db.session.commit()
        return jsonify(sensor.to_dict())


@api.route('/sensor/<uuid>/', methods=['PUT'])
def update_sensor(uuid):
    sensor = Sensor.query.filter_by(uuid=uuid).first_or_404()
    for field in request.json.keys():
        if field in Sensor.editable_fields():
            setattr(sensor, field, request.json[field])
        elif field in Sensor.fields():
            return error_response(
                    errors.FIELD_NOT_EDITABLE.format(field), 400)
        else:
            return error_response(
                    errors.FIELD_INVALID.format(field), 400)
    else:
        db.session.commit()
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
                errors.FIELDS_MISSING.format(missing), 400)
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
        db.session.add(attack)
        db.session.commit()
        return jsonify(attack.to_dict())
