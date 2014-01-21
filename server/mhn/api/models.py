from datetime import datetime

from sqlalchemy import UniqueConstraint

from mhn import db


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
            db.DateTime(),default=datetime.utcnow)
    ip = db.Column(db.String(15))
    hostname = db.Column(db.String(50))
    attacks = db.relationship(
            'Attack', backref='sensor', lazy='dynamic')

    def __init__(
          self, uuid=None, name=None, created_date=None,
          ip=None, hostname=None):
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
