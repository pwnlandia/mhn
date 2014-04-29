from flask.ext.security import UserMixin, RoleMixin

from mhn import db
from mhn.api import APIModel


roles_users = db.Table(
        'roles_users', db.Column('user_id', db.Integer(), db.ForeignKey('user.id')),
        db.Column('role_id', db.Integer(), db.ForeignKey('role.id')))


class Role(db.Model, RoleMixin):
    id = db.Column(db.Integer(), primary_key=True)
    name = db.Column(db.String(80), unique=True)
    description = db.Column(db.String(255))


class User(db.Model, APIModel, UserMixin):
    all_fields = {
        'email': {'required': True, 'editable': False},
        'username': {'required': True, 'editable': False},
        'password': {'required': True, 'editable': True},
        'active': {'required': False, 'editable': True}
    }

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True)
    username = db.Column(db.String(255))
    password = db.Column(db.String(255))
    active = db.Column(db.Boolean())
    confirmed_at = db.Column(db.DateTime())
    roles = db.relationship('Role', secondary=roles_users,
                            backref=db.backref('users', lazy='dynamic'))

    def to_dict(self):
        return dict(
                email=self.email, roles=[r.name for r in self.roles],
                username=self.username, active=self.active)
