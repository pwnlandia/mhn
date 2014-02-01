from flask import jsonify, g
from flask.ext.sqlalchemy import Pagination

from mhn.constants import PAGE_SIZE


def error_response(message, status_code):
    resp = jsonify({'error': message})
    resp.status_code = status_code
    return resp


def paginate(query):
    items = query.\
            offset((g.page - 1) * PAGE_SIZE).\
            limit(PAGE_SIZE)
    return Pagination(query, g.page, PAGE_SIZE,
                      query.count(), items)
