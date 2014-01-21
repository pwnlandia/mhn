from flask import jsonify


def error_response(message, status_code):
    resp = jsonify({'error': message})
    resp.status_code = status_code
    return resp
