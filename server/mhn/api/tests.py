import json
from uuid import uuid1

from flask import url_for

from mhn import db
from mhn.common.testcommon import MHNTestCase
from mhn.api.models import Sensor


class SensorTestCase(MHNTestCase):

    def setUp(self):
        super(SensorTestCase, self).setUp()
        self.sensordata = dict(hostname='mhn.test.sensor', name='Test Sensor')
        self.deploykey = self.app.config['DEPLOY_KEY']
        self.publish_dict = self.app.config['HONEYPOT_CHANNELS']

    def test_create_sensor(self):
        create_url = url_for('api.create_sensor')
        data = self.sensordata.copy()
        data.update({'deploy_key': self.deploykey, 'honeypot': 'conpot'})

        # Registering a sensor with deploy_key in post body.
        resp = self.client.post(create_url, data=json.dumps(data),
                               content_type='application/json')
        resp = json.loads(resp.data)
        authkey = self.clio.authkey.get(identifier=resp['uuid'])
        sensor = Sensor.query.first()

        # Asserts correct authkey object was created on the database.
        self.assertEqual(authkey.identifier, sensor.uuid)
        self.assertEqual(authkey.publish, self.publish_dict[sensor.honeypot])
        # Asserts sensor was creating with correct attributes.
        self.assertEqual(sensor.name, self.sensordata['name'])
        self.assertEqual(sensor.hostname, self.sensordata['hostname'])
        self.assertEqual(sensor.honeypot, data['honeypot'])

    def test_delete_sensor(self):
        data = self.sensordata.copy()
        data['honeypot'] = 'conpot'

        # Create sensor and respective authkey.
        sensor = Sensor(**data)
        sensor.uuid = str(uuid1())
        self.clio.authkey.new(**sensor.new_auth_dict()).post()
        db.session.add(sensor)
        db.session.commit()

        # Objects before should equal 1.
        sensors_before = Sensor.query.count()
        keys_before = self.clio.authkey.count()

        # Logging in and making the DELETE request.
        self.login()
        delete_url = url_for('api.delete_sensor', uuid=sensor.uuid)
        self.client.delete(delete_url)

        # Sensors after should equal 0.
        sensors_after = Sensor.query.count()
        keys_after = self.clio.authkey.count()

        # Asserts that both sensor and authkey got deleted.
        self.assertEqual(sensors_before, sensors_after + 1)
        self.assertEqual(keys_before, keys_after + 1)
