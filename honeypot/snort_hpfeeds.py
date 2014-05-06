#!/usr/bin/env python

"""Modern Honeypot Network - snort alerts to hpfeeds service.

Usage:
    snort_hpfeeds.py -c <config_path>

Options:
    -c <config_path>                Path to config file to use.
"""
import os
import json
import time
import logging
from docopt import docopt
from os import path, makedirs

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

from util import safe_pickle, safe_unpickle
from snort import Alert
import hpfeeds

logger = logging.getLogger('snort_hpfeeds')

class SnortHpFeedsService(object):
    def __init__(self, sensor_uuid, alert_file, host, port, ident, secret):
        hpc = hpfeeds.new(host=host, port=port, ident=ident, secret=secret)
        self.alerter = AlertEventHandler(sensor_uuid, alert_file, hpc)

    def run(self):
        self.alerter.observer.start()
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            self.cleanup()

    def cleanup(self):
        if self.alerter.observer.isAlive():
            self.alerter.observer.stop()
            self.alerter.observer.join()

class AlertEventHandler(FileSystemEventHandler):
    def __init__(self, sensor_uuid, alert_file, hpc):
        """
        Initializes a filesytem watcher that will watch
        the specified file for changes.
        `alert_file` is the absolute path of the snort alert file.
        `hpc` is the hpfeeds client
        """
        self.sensor_uuid = sensor_uuid
        self.alert_file = alert_file
        self.hpc = hpc
        logger.info('connected to hpfeeds broker {}'.format(hpc.brokername))

        self.observer = Observer()
        self.observer.schedule(self, alert_file, False)
        
    @property
    def latest_alert_date(self):
        return safe_unpickle('alert_date.pkl')

    @latest_alert_date.setter
    def latest_alert_date(self, date):
        safe_pickle('alert_date.pkl', date)

    def on_any_event(self, event):
        if (not event.event_type == 'deleted') and (event.src_path == self.alert_file):
            alerts = Alert.from_log(self.sensor_uuid, self.alert_file, self.latest_alert_date)
            if alerts:
                logger.info("submitting {} alerts to {}".format(len(alerts), hpc.brokername))
                alerts.sort(key=lambda e: e.date)
                self.latest_alert_date = alerts[-1].date            
                
                for alert in new_alerts:
                    self.hpc.publish("snort.events", alert.to_json())

def config_logger():
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s  -  %(name)s - %(message)s')
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    console.setFormatter(formatter)
    logger.addHandler(console)

if __name__ ==  '__main__':
    args = docopt(__doc__, version='snort_hpfeeds 0.0.1')
    with open(args.get('-c')) as config:
        try:
            cfg = json.loads(config.read())
        except ValueError:
            raise SystemExit("Error parsing config file.")

    print cfg

    snort_hpfeeds_service = SnortHpFeedsService(
        sensor_uuid=cfg['sensor_uuid'],
        alert_file=cfg['alert_file'],
        host=cfg['host'],
        port=cfg['port'],
        ident=cfg['ident'].encode('latin1'),
        secret=cfg['secret'].encode('latin1')
    )
    config_logger()
    snort_hpfeeds_service.run()
