import json
from uuid import uuid1

from flask import Blueprint, request, jsonify

from mhn import db
from mhn.api import errors
from mhn.api.models import Sensor
from mhn.api.errors import error_response


api = Blueprint('api', __name__, url_prefix='/api')


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
            return response
    else:
        db.session.commit()
        return jsonify(sensor.to_dict())


@api.route('/sensor/<uuid>/connect/', methods=['POST'])
def connect_sensor(uuid):
    sensor = Sensor.query.filter_by(uuid=uuid).first_or_404()
    sensor.ip = request.remote_addr
    db.session.commit()
    return jsonify(sensor.to_dict())
