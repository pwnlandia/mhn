"""Modern Honeypot Network - Client version.

Usage:
    mhnclient.py -c <config_path>

Options:
    -c <config_path>                Path to config file to use.
"""
import json
import time
import logging
from os import path
from itertools import groupby
from datetime import datetime, timedelta

import requests
import pyparsing as pyp
from docopt import docopt
from sqlalchemy import (
        create_engine, String, Integer, Column,
        Float)
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler


logger = logging.getLogger('mhnclient')


class MHNClient(object):

    def __init__(self, **kwargs):
        self.api_url = kwargs.get('api_url')
        self.sensor_uuid = kwargs.get('sensor_uuid')
        self.session = requests.Session()
        self.session.auth = (self.sensor_uuid, self.sensor_uuid)
        self.session.headers = {'Content-Type': 'application/json'}

        def on_new_alerts(new_alerts):
            logger.info("Detected {} new alerts. Posting to '{}'.".format(
                    len(new_alerts), self.attack_url))
            for al in new_alerts:
                self.post_attack(al)
        self.alerter = AlertEventHandler(
                self.sensor_uuid, kwargs.get('alert_file'),
                kwargs.get('dionaea_db'), on_new_alerts)

    def connect_sensor(self):
        connresp = self.session.post(self.connect_url)
        logger.info("Started Honeypot '{}' on {}.".format(
                connresp.json().get('hostname'), connresp.json().get('ip')))
        self.alerter.observer.start()

    def post_attack(self, alert):
        self.session.post(self.attack_url, data=alert.to_json())

    @property
    def attack_url(self):
        return '{}/attack/'.format(self.api_url)

    @property
    def connect_url(self):
        return '{}/sensor/{}/connect/'.format(self.api_url,
                                              self.sensor_uuid)


# SQLAlchemy's built-in declarative base class.
Base = declarative_base()


class Connection(Base):

    __tablename__ = 'connections'
    connection = Column(Integer, primary_key=True)
    connection_type = Column(String(15))
    connection_protocol = Column(String(15))
    connection_timestamp = Column(Float())
    connection_root = Column(Integer)
    local_host = Column(String(15))
    local_port = Column(String(6))
    remote_host = Column(String(15))
    remote_hostname = Column(String(20))
    remote_port = Column(String(6))

    def to_dict(self):
        return dict(connection=self.connection,
                    connection_type=self.connection_type,
                    connection_protocol=self.connection_protocol,
                    connection_timestamp=self.connection_timestamp,
                    connection_root=self.connection_root,
                    local_host=self.local_host, local_port=self.local_port,
                    remote_host=self.remote_host, remote_port=self.remote_port,
                    remote_hostname=self.remote_hostname)

    def to_json(self):
        date = datetime.utcfromtimestamp(self.connection_timestamp)
        _dict = self.to_dict()
        _dict['date'] = date.strftime("%Y-%m-%dT%H:%M:%S.%f%z")
        return json.dumps(_dict)

    def __repr__(self):
        return str(self.to_dict())


class Alert(object):
    """
    Represents a Snort alert.
    """

    fields = (
        'header',
        'classification',
        'priority',
        'date',
        'source_ip',
        'destination_ip',
        'destination_port'
    )

    def __init__(self, sensor_uuid, *args):
        try:
            assert len(args) == 7
        except:
            raise ValueError("Unexpected number of attributes.")
        else:
            self.header = args[0]
            self.classification = args[1]
            self.priority = args[2]
            # Alert logs don't include year. Creating a datime object
            # with current year.
            date = datetime.strptime(args[3], '%m/%d-%H:%M:%S.%f')
            self.date = datetime(
                    datetime.now().year, date.month, date.day,
                    date.hour, date.minute, date.second, date.microsecond)
            self.source_ip = args[4]
            self.destination_ip = args[5]
            self.destination_port = args[6]
            self.sensor = sensor_uuid

    def __repr__(self):
        return str(self.__dict__)

    def to_dict(self):
        return self.__dict__

    def to_json(self):
        _dict = self.to_dict().copy()
        _dict.update({'date': self.date.strftime("%Y-%m-%dT%H:%M:%S.%f%z")})
        return json.dumps(_dict)

    @classmethod
    def from_log(cls, sensor_uuid, logfile, mindate=None):
        """
        Reads the file logfile and parses out Snort alerts
        from the given alert format.
        Thanks to 'unutbu' at StackOverflow.
        """
        # Defining generic pyparsing objects.
        integer = pyp.Word(pyp.nums)
        ip_addr = pyp.Combine(integer + '.' + integer+ '.' + integer + '.' + integer)
        port = pyp.Suppress(':') + integer

        # Defining pyparsing objects from expected format:
        #
        #    [**] [1:160:2] COMMUNITY SIP TCP/IP message flooding directed to SIP proxy [**]
        #    [Classification: Attempted Denial of Service] [Priority: 2]
        #    01/10-00:08:23.598520 201.233.20.33:63035 -> 192.234.122.1:22
        #    TCP TTL:53 TOS:0x10 ID:2145 IpLen:20 DgmLen:100 DF
        #    ***AP*** Seq: 0xD34C30CE  Ack: 0x6B1F7D18  Win: 0x2000  TcpLen: 32
        #
        # Note: This format is known to change over versions.
        # Works with Snort version 2.9.2 IPv6 GRE (Build 78)

        header = (
        pyp.Suppress("[**] [")
        + pyp.Combine(integer + ":" + integer + ":" + integer)
        + pyp.Suppress(pyp.SkipTo("[**]", include=True))
        )
        classif = (
            pyp.Suppress(pyp.Optional(pyp.Literal("[Classification:")))
            + pyp.Regex("[^]]*") + pyp.Suppress(']')
        )
        pri = pyp.Suppress("[Priority:") + integer + pyp.Suppress("]")
        date = pyp.Combine(
            integer + "/" + integer + '-' + integer + ':' + integer + ':' + integer + '.' + integer)
        src_ip = ip_addr + pyp.Suppress(port + "->")
        dest_ip = ip_addr
        dest_port = port
        bnf = header + classif + pri + date + src_ip + dest_ip + dest_port

        alerts = []
        with open(logfile) as snort_logfile:
            for has_content, grp in groupby(
                    snort_logfile, key = lambda x: bool(x.strip())):
                if has_content:
                    content = ''.join(grp)
                    fields = bnf.searchString(content)
                    if fields:
                        alert = cls(sensor_uuid, *fields[0])
                        if (mindate and alert.date > mindate) or not mindate:
                            # If mindate parameter is passed, only newer
                            # alters will be appended.
                            alerts.append(alert)
        return alerts


class AlertEventHandler(FileSystemEventHandler):

    def __init__(self, sensor_uuid, alert_file,
                 dbpath, on_new_alerts):
        """
        Initializes a filesytem watcher that will watch
        the specified file for changes.
        `alert_file` is the absolute path of the snort alert file.
        `dbpath` is the absolute path of the dionaea sqlite file
        that will be watched.
        `on_new_alerts` is a callback that will get called
        once new alerts are found.
        """
        db_dir = path.dirname(dbpath)
        self.alert_file = alert_file
        self.dbpath = dbpath
        self.latest_date = None
        self.observer = Observer()
        self.observer.schedule(self, db_dir, False)
        self._on_new_alerts = on_new_alerts
        self.sensor_uuid = sensor_uuid
        self.engine = create_engine(
                'sqlite:///{}'.format(self.dbpath), echo=False)
        self.session = sessionmaker(bind=self.engine)()
        self.latest_conn_id = 0

    def query_connections(self, mindate=None):
        conns = self.session.query(Connection)
        if mindate:
            # Calculate UNIX timestamp of mindate.
            mindatestamp = (mindate - datetime(1970, 1, 1)).total_seconds()
            conns.filter(
                Connection.connection_timestamp > mindatestamp)
        return conns

    def on_any_event(self, event):
        if (not event.event_type == 'deleted') and\
           (event.src_path == self.dbpath):
            alerts = Alert.from_log(
                    self.sensor_uuid, self.alert_file, self.latest_date)
            conns = self.query_connections()
            if conns:
                pass
            if alerts:
                # latest_date is used as a mechanism to
                # prevent processing alerts more than once.
                alerts.sort(key=lambda e: e.date)
                self.latest_date = alerts[-1].date
                self._on_new_alerts(alerts)


def config_logger(logfile):
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s  -  %(name)s - %(message)s')
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    console.setFormatter(formatter)
    logger.addHandler(console)
    if logfile:
        from logging.handlers import RotatingFileHandler

        rotatelog = RotatingFileHandler(
                logfile, maxBytes=10240, backupCount=5)
        rotatelog.setLevel(logging.INFO)
        rotatelog.setFormatter(formatter)
        logger.addHandler(rotatelog)


if __name__ ==  '__main__':
    args = docopt(__doc__, version='MHNClient 0.0.1')
    with open(args.get('-c')) as config:
        try:
            configdict = json.loads(config.read())
        except ValueError:
            raise SystemExit("Error parsing config file.")
    config_logger(configdict.get('log_file'))
    honeypot = MHNClient(**configdict)
    honeypot.connect_sensor()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        honeypot.alerter.observer.stop()
        honeypot.alerter.observer.join()
