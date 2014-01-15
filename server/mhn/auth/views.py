from flask import Blueprint, request, jsonify
from sqlalchemy.exc import IntegrityError
from flask_security.utils import (
        login_user as login, verify_and_update_password, encrypt_password)

from mhn import db
from mhn.common.utils import error_response
from mhn.auth.models import User
from mhn.auth import errors
from mhn.auth import (
    get_datastore, login_required, roles_accepted, current_user)


auth = Blueprint('auth', __name__, url_prefix='/auth')


@auth.route('/login/', methods=['POST'])
def login_user():
    if 'email' not in request.json:
        return error_response(errors.AUTH_EMAIL_MISSING, 400)
    if 'password' not in request.json:
        return error_response(errors.AUTH_PSSWD_MISSING, 400)
    # email and password are in the posted data.
    user = User.query.filter_by(
            email=request.json.get('email')).first()
    psswd_check = False
    if user:
        psswd_check = verify_and_update_password(
                request.json.get('password'), user)
    if user and psswd_check:
        login(user, remember=True)
        return jsonify(user.to_dict())
    else:
        return error_response(errors.AUTH_INCORRECT_CREDENTIALS, 401)


@auth.route('/register/', methods=['POST'])
@roles_accepted('admin')
def create_user():
    if 'email' not in request.json:
        return error_response(errors.AUTH_EMAIL_MISSING, 400)
    if 'password' not in request.json:
        return error_response(errors.AUTH_PSSWD_MISSING, 400)
    user = get_datastore().create_user(
             email=request.json.get('email'),
             password=encrypt_password(request.json.get('password')))
    try:
        db.session.add(user)
        db.session.commit()
        return jsonify(user.to_dict())
    except IntegrityError:
        return error_response(errors.AUTH_USERNAME_EXISTS, 400)


@auth.route('/me/', methods=['GET'])
@login_required
def get_user():
    return jsonify(current_user.to_dict())
