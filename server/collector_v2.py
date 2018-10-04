import sys
import json
import hpfeeds
import logging
from hpfeedslogger import processors
import pymongo
import requests

ch = logging.StreamHandler(sys.stdout)
ch.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger = logging.getLogger("collector")
logger.addHandler(ch)
logger.setLevel(logging.DEBUG)

DEFAULT_CHANNELS = [
    "amun.events",
    "beeswarm.hive",
    "conpot.events",
    "dionaea.capture",
    "dionaea.connections",
    "elastichoney.events",
    "glastopf.events",
    "kippo.sessions",
    "p0f.events",
    "shockpot.events",
    "snort.alerts",
    "suricata.events",
    "wordpot.events",
]

def ensure_user_permissions(ident, secret, publish, subscribe):
    rec = {
        "identifier": ident,
        "secret": secret,
        "publish": publish,
        "subscribe":subscribe
    }

    client = pymongo.MongoClient()
    res = client.hpfeeds.auth_key.update({"identifier": ident}, {"$set": rec}, upsert=True)
    client.fsync()
    client.close()

def hpfeeds_connect(host, port, ident, secret):
    logger.info('Connecting to %s@%s:%s ...', ident, host, port)
    try:
        connection = hpfeeds.new(host, port, ident, secret)
    except hpfeeds.FeedException, e:
        logger.error('feed exception: %s'%e)
        sys.exit(1)
    logger.info('connected to %s (%s:%s)'%(connection.brokername, host, port))
    return connection

def main():
    cfg = dict(
        HOST='localhost',
        PORT=10000,
        CHANNELS=DEFAULT_CHANNELS,
        IDENT='collector',
        RHOST='mhnbroker.threatstream.com',
        RPORT=10000,
        RCHANNEL='mhn-community-v2.events',
        RIDENT='mhn-server',
        RSECRET='mhn-secret',
        IP_GEO_DB="/opt/GeoLiteCity.dat",
        IP_ASN_DB="/opt/GeoIPASNum.dat",
    )

    if len(sys.argv) > 1:
        logger.info("Parsing config file: %s", sys.argv[1])
        cfg.update(json.load(file(sys.argv[1])))

        for name, value in cfg.items():
            if isinstance(value, basestring):
                # hpfeeds protocol has trouble with unicode, hence the utf-8 encoding here
                cfg[name] = value.encode("utf-8")
            if isinstance(value, list):
                # hpfeeds protocol has trouble with unicode, hence the utf-8 encoding here
                cfg[name] = [val.encode('utf-8') for val in value]
    else:
        logger.warning("Warning: no config found, using default values for hpfeeds server")

    try:
        ip = requests.get('https://myip.threatstream.com', headers={'User-Agent': 'mhn-collector-v2'}).text.strip()
    except:
        ip = None
    mhn_uuid = cfg['MHN_UUID']

    ensure_user_permissions(cfg['IDENT'], cfg['SECRET'], [], cfg['CHANNELS'])
    subscriber = hpfeeds_connect(cfg['HOST'], cfg['PORT'], cfg['IDENT'], cfg['SECRET'])
    publisher = hpfeeds_connect(cfg['RHOST'], cfg['RPORT'], cfg['RIDENT'], cfg['RSECRET'])
    processor = processors.HpfeedsMessageProcessor(cfg['IP_GEO_DB'], cfg['IP_ASN_DB'])

    def on_message(identifier, channel, payload):
        try:
            results = processor.process(identifier, channel, payload, ignore_errors=True)
            for message in results:
                message['mhn_uuid'] = mhn_uuid
                message['mhn_ip'] = ip

                if 'dest_ip' in message:
                    # remove the honeypot IP if there is one
                    del message['dest_ip']

                publisher.publish(cfg['RCHANNEL'], json.dumps(message))
        except Exception as e:
            logger.exception(e)
            pass

    def on_error(payload):
        logger.error(' -> errormessage from server: {0}'.format(payload))
        subscriber.stop()
        publisher.stop()

    subscriber.subscribe(cfg['CHANNELS'])
    try:
        subscriber.run(on_message, on_error)
    except hpfeeds.FeedException, e:
        logger.error('feed exception: %s', e)
    except KeyboardInterrupt:
        pass
    except:
        import traceback
        traceback.print_exc()
    finally:
        subscriber.close()
        publisher.close()
    return 0

if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(0)
