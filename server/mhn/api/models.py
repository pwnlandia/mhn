from datetime import datetime

from sqlalchemy import UniqueConstraint, func

from mhn import db
from mhn.auth.models import User


class APIModel(object):
    @classmethod
    def fields(cls):
        return cls.all_fields.keys()

    @classmethod
    def editable_fields(cls):
        return cls._make_field_list('editable')

    @classmethod
    def required_fields(cls):
        return cls._make_field_list('required')

    @classmethod
    def _make_field_list(cls, prop):
        """
        Returns a list of field names that have the property
        `prop` in the `all_fields` dictionary defined at
        class level.
        """
        return [f for f, e in cls.all_fields.items() if e.get(prop, False)]

    @classmethod
    def check_required(cls, payload):
        """
        Returns a list of required fields that are
        missing from the dictionary object `payload`.
        """
        missing = []
        for field in cls.required_fields():
            if (field not in payload) or payload.get(field) == '':
                missing.append(field)
        return missing


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
        'hostname': {'required': True, 'editable': True}
    }

    __tablename__ = 'sensors'

    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String(36), unique=True)
    name = db.Column(db.String(50), unique=True)
    created_date = db.Column(
            db.DateTime(), default=datetime.utcnow)
    ip = db.Column(db.String(15))
    hostname = db.Column(db.String(50), unique=True)
    attacks = db.relationship(
            'Attack', backref='sensor', lazy='dynamic')

    def __init__(
          self, uuid=None, name=None, created_date=None,
          ip=None, hostname=None, **args):
        self.uuid = uuid
        self.name = name
        self.created_date = created_date
        self.ip = ip
        self.hostname = hostname

    def __repr__(self):
        return '<Sensor>{}'.format(self.to_dict())

    def to_dict(self):
        return dict(
            uuid=self.uuid, name=self.name,
            created_date=self.created_date, ip=self.ip,
            hostname=self.hostname)


class Attack(db.Model, APIModel):

    # Defines some properties on the fields:
    # required: Is required for creating object via
    #           a POST request.
    # editable: Can be edited via a PUT request.
    # Defaults to False.
    all_fields = {
        'source_ip': {'required': True},
        'destination_ip': {'required': True},
        'destination_port': {'required': True},
        'priority': {},
        'date': {'required': True},
        'sensor': {'required': True}
    }

    __tablename__ = 'attacks'

    id = db.Column(db.Integer, primary_key=True)
    source_ip = db.Column(db.String(15))
    destination_ip = db.Column(db.String(15))
    destination_port = db.Column(db.Integer)
    priority = db.Column(db.Integer)
    date = db.Column(db.DateTime())
    classification = db.Column(db.String(80))
    sensor_id = db.Column(db.Integer,
                          db.ForeignKey('sensors.id'))
    __table_args__ = (UniqueConstraint(source_ip, destination_ip,
                                       destination_port, date, sensor_id),)

    def __init__(
            self, source_ip=None, destination_ip=None,
            destination_port=None, priority=None, date=None,
            classification=None):
        self.source_ip = source_ip
        self.destination_ip = destination_ip
        self.destination_port = destination_port
        self.priority = priority
        self.date = date
        self.classification = classification

    def __repr__(self):
        return '<Attack>{}'.format(self.to_dict())

    def to_dict(self):
        return dict(
            source_ip=self.source_ip, destination_ip=self.destination_ip,
            destination_port=self.destination_port, priority=self.priority,
            date=self.date, classification=self.classification,
            sensor=self.sensor.hostname)


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
        'date': {'required': False, 'editable': False},
        'notes': {'required': True, 'editable': True},
    }

    __tablename__ = 'deploy_scripts'

    id = db.Column(db.Integer, primary_key=True)
    script = db.Column(db.String(102400))
    date = db.Column(
             db.DateTime(), default=datetime.utcnow)
    notes = db.Column(db.String(140))
    user_id = db.Column(db.Integer, db.ForeignKey(User.id))
    user = db.relationship(User, uselist=False)

    def __init__(self, script=None, notes=None):
        self.script = script
        self.notes = notes

    def __repr__(self):
        return '<DeployScript>{}'.format(self.to_dict())

    def to_dict(self):
        return dict(script=self.script, date=self.date, notes=self.notes,
                    user=self.user.email)


class TarUpload(db.Model):

    __tablename__ = 'tar_uploads'
    id = db.Column(db.Integer, primary_key=True)
    date = db.Column(
             db.DateTime(), default=datetime.utcnow)
    user_id = db.Column(db.Integer, db.ForeignKey(User.id))
    user = db.relationship(User, uselist=False)
