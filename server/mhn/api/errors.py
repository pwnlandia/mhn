from flask import jsonify


FIELD_NOT_EDITABLE = '"{}" field is not editable.'

FIELD_INVALID = '"{}" invalid field.'

FIELDS_MISSING = 'Missing required fields: {}.'


def error_response(message, status_code):
    resp = jsonify({'error': message})
    resp.status_code = status_code
    return resp
