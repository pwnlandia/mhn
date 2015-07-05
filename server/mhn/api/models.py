import string
from random import choice
from datetime import datetime

from sqlalchemy import UniqueConstraint, func

from mhn import db
from mhn.api import APIModel
from mhn.auth.models import User
from mhn.common.clio import Clio


class Sensor(db.Model, APIModel):

    # Defines some properties on the fields:
    # required: Is required for creating object via
    #           a POST request.
    # editable: Can be edited via a PUT request.
    all_fields = {
        'uuid': {'required': False, 'editable': False},
        'name': {'required': True, 'editable': True},
        'created_date': {'required': False, 'editable': False},
        'ip': {'required': False, 'editable': False},
        'hostname': {'required': True, 'editable': True},
        'honeypot': {'required': True, 'editable': False}
    }

    __tablename__ = 'sensors'

    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String(36), unique=True)
    name = db.Column(db.String(50))
    created_date = db.Column(
            db.DateTime(), default=datetime.utcnow)
    ip = db.Column(db.String(15))
    hostname = db.Column(db.String(50))
    identifier = db.Column(db.String(50), unique=True)
    honeypot = db.Column(db.String(50))

    def __init__(
          self, uuid=None, name=None, created_date=None, honeypot=None,
          ip=None, hostname=None, identifier=None, **args):
        self.uuid = uuid
        self.name = name
        self.created_date = created_date
        self.ip = ip
        self.hostname = hostname
        self.identifier = identifier
        self.honeypot = honeypot

    def __repr__(self):
        return '<Sensor>{}'.format(self.to_dict())

    def to_dict(self):
        return dict(
            uuid=self.uuid, name=self.name, honeypot=self.honeypot,
            created_date=str(self.created_date), ip=self.ip,
            hostname=self.hostname, identifier=self.uuid,
            # Extending with info from Mnemosyne.
            secret=self.authkey.secret, publish=self.authkey.publish)

    def new_auth_dict(self):
        el = string.ascii_letters + string.digits
        rand_str = lambda n: ''.join(choice(el) for _ in range(n))
        return dict(secret=rand_str(16),
                    identifier=self.uuid, honeypot=self.honeypot,
                    subscribe=[], publish=Sensor.get_channels(self.honeypot))

    @property
    def attacks_count(self):
        return Clio().counts.get_count(identifier=self.uuid)

    @property
    def authkey(self):
        return Clio().authkey.get(identifier=self.uuid)

    @staticmethod
    def get_channels(honeypot):
        from mhn import mhn
        return mhn.config.get('HONEYPOT_CHANNELS', {}).get(honeypot, [])


class Rule(db.Model, APIModel):

    # Defines some properties on the fields:
    # required: Is required for creating object via
    #           a POST request.
    # editable: Can be edited via a PUT request.
    # Defaults to False.
    all_fields = {
        'message': {'required': True, 'editable': True},
        'references': {'required': True, 'editable': False},
        'classtype': {'required': True, 'editable': True},
        'sid': {'required': True, 'editable': False},
        'rev': {'required': True, 'editable': True},
        'date': {'required': False, 'editable': False},
        'rule_format': {'required': True, 'editable': False},
        'is_active': {'required': False, 'editable': True},
        'notes': {'required': False, 'editable': True}
    }

    __tablename__ = 'rules'

    id = db.Column(db.Integer, primary_key=True)
    message = db.Column(db.String(140))
    references = db.relationship(
            'Reference', backref='rule', lazy='dynamic')
    classtype = db.Column(db.String(50))
    sid = db.Column(db.Integer)
    rev = db.Column(db.Integer)
    date = db.Column(db.DateTime(), default=datetime.utcnow)
    rule_format = db.Column(db.String(500))
    is_active = db.Column(db.Boolean)
    notes = db.Column(db.String(140))
    __table_args__ = (UniqueConstraint(sid, rev),)

    def __init__(self, msg=None, classtype=None, sid=None,
                 rev=None, date=None, rule_format=None, **args):
        self.message = msg
        self.classtype = classtype
        self.sid = sid
        self.rev = rev
        self.rule_format = rule_format
        self.is_active = True

    def insert_refs(self, refs):
        for r in refs:
            ref = Reference()
            ref.rule = self
            ref.text = r
            db.session.add(ref)
        db.session.commit()

    def to_dict(self):
        return dict(sid=self.sid, rev=self.rev, msg=self.message,
                    classtype=self.classtype, is_active=self.is_active)

    def __repr__(self):
        return '<Rule>{}'.format(self.to_dict())

    def render(self):
        """
        Takes Rule model and renders itself to plain text.
        """
        msg = 'msg:"{}"'.format(self.message)
        classtype = 'classtype:{}'.format(self.classtype)
        sid = 'sid:{}'.format(self.sid)
        rev = 'rev:{}'.format(self.rev)
        reference = ''
        for r in self.references:
            reference += 'reference:{}; '.format(r.text)
        # Remove trailing '; ' from references.
        reference = reference[:-2]
        return self.rule_format.format(msg=msg, sid=sid, rev=rev,
                                       classtype=classtype, reference=reference)

    @classmethod
    def renderall(cls):
        """
        Renders latest revision of active rules.
        This method must be called within a Flask app
        context.
        """
        rules = cls.query.filter_by(is_active=True).\
                    group_by(cls.sid).\
                    having(func.max(cls.rev))
        return '\n\n'.join([ru.render() for ru in rules])

    @classmethod
    def bulk_import(cls, rulelist):
        """
        Imports rules into the database.
        This method must be called within a Flask app
        context.
        """
        cnt = 0
        for ru in rulelist:
            # Checking for rules with this sid.
            if cls.query.\
                   filter_by(sid=ru['sid']).\
                   filter(cls.rev >= ru['rev']).count() == 0:
                # All rules with this sid have lower rev number that
                # the incoming one, or this is a new sid altogether.
                rule = cls(**ru)
                rule.insert_refs(ru['references'])
                db.session.add(rule)
                # Disabling older rules.
                cls.query.\
                    filter_by(sid=ru['sid']).\
                    filter(cls.rev < ru['rev']).\
                    update({'is_active': False}, False)
            cnt += 1
            if cnt % 500 == 0:
                print 'Imported {} rules so far...'.format(cnt)
        print 'Finished Importing {} rules.  Committing data'.format(cnt)
        db.session.commit()


class RuleSource(db.Model, APIModel):

    all_fields = {
        'uri': {'required': True, 'editable': True},
        'note': {'required': False, 'editable': True},
        'name': {'required': True, 'editable': True},
    }

    __tablename__ = 'rule_sources'
    id = db.Column(db.Integer, primary_key=True)
    uri = db.Column(db.String(140))
    note = db.Column(db.String(140))
    name = db.Column(db.String(40))

    def  __repr__(self):
        return '<RuleSource>{}'.format(self.to_dict())

    def to_dict(self):
        return dict(name=self.name, uri=self.uri, note=self.note)


class Reference(db.Model):

    __tablename__ = 'rule_references'

    id = db.Column(db.Integer, primary_key=True)
    text = db.Column(db.String(140))
    rule_id = db.Column(db.Integer,
                        db.ForeignKey('rules.id'))


class DeployScript(db.Model, APIModel):
    all_fields = {
        'script': {'required': True, 'editable': True},
        'name': {'required': True, 'editable': True},
        'date': {'required': False, 'editable': False},
        'notes': {'required': True, 'editable': True},
    }

    __tablename__ = 'deploy_scripts'

    id = db.Column(db.Integer, primary_key=True)
    script = db.Column(db.String(102400))
    date = db.Column(
             db.DateTime(), default=datetime.utcnow)
    notes = db.Column(db.String(140))
    name = db.Column(db.String(140))
    user_id = db.Column(db.Integer, db.ForeignKey(User.id))
    user = db.relationship(User, uselist=False)

    def __init__(self, name=None, script=None, notes=None):
        self.name = name
        self.script = script
        self.notes = notes

    def __repr__(self):
        return '<DeployScript>{}'.format(self.to_dict())

    def to_dict(self):
        return dict(script=self.script, date=self.date, notes=self.notes,
                    user=self.user.email, id=self.id)
