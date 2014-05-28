import os
import json

from flask import url_for
from flask.ext.testing import TestCase
import pymongo

import mhn.common.clio as clio
from mhn import create_clean_db, mhn, db


# Patching clio to use different database than production.
clio_res = (clio.AuthKey, clio.ResourceMixin,)
for res in clio_res:
    res.db_name = 'test_{}'.format(res.db_name)
# End patching.


class MHNTestCase(TestCase):

    def __init__(self, *args, **kwargs):
        super(MHNTestCase, self).__init__(*args, **kwargs)
        self.clio = clio.Clio()

    def create_app(self):
        _basedir = os.path.abspath(os.path.dirname(__file__))
        db_uri = 'sqlite:///' + os.path.join(_basedir, 'test-mhn.db')
        mhn.config['SQLALCHEMY_DATABASE_URI'] = db_uri
        mhn.config['TESTING'] = True
        return mhn

    def setUp(self):
        create_clean_db()
        self.email = self.app.config['SUPERUSER_EMAIL']
        self.passwd = self.app.config['SUPERUSER_PASSWORD']

    def tearDown(self):
        db.session.remove()
        db.drop_all()

        # Removing test collections from mongo.
        cli = pymongo.MongoClient()
        for dbname in cli.database_names():
            if dbname.startswith('test_'):
                cli.drop_database(dbname)

    def login(self, email=None, password=None):
        if email is None:
            email = self.email
        if password is None:
            password = self.passwd
        login_url = url_for('auth.login_user')
        logindata = json.dumps(dict(email=email, password=password))
        self.client.post(login_url, data=logindata, content_type='application/json')
