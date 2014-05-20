import sys
import datetime
import json
import hpfeeds
import logging

root = logging.getLogger()
root.setLevel(logging.ERROR)

ch = logging.StreamHandler(sys.stdout)
ch.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
root.addHandler(ch)
logger = logging.getLogger("collector")

def hpfeeds_connect(host, port, ident, secret):
    try:
        connection = hpfeeds.new(host, port, ident, secret)
    except hpfeeds.FeedException, e:
        logger.error('feed exception: %s'%e)
        sys.exit(1)
    logger.info('connected to %s (%s:%s)'%(connection.brokername, host, port))
    return connection

def main():
    cfg = dict(
        HOST = 'localhost',
        PORT = 10000,
        GEOLOC_CHAN = 'geoloc.events',
        IDENT = '',
        SECRET = '',
        RHOST = 'mhnbroker.threatstream.com',
        RPORT = 10000,
        RCHANNEL = 'mhn-community.events',
        RIDENT  = 'mhn-server',
        RSECRET = 'mhn-secret'
    )

    if len(sys.argv) > 1:
        logger.info("Parsing config file: %s"%sys.argv[1])
        cfg.update(json.load(file(sys.argv[1])))

        for name,value in cfg.items():
            if isinstance(value, basestring):
                # hpfeeds protocol has trouble with unicode, hence the utf-8 encoding here
                cfg[name] = value.encode("utf-8")
    else:
        logger.warning("Warning: no config found, using default values for hpfeeds server")

    subscriber = hpfeeds_connect(cfg['HOST'], cfg['PORT'], cfg['IDENT'], cfg['SECRET'])
    publisher  = hpfeeds_connect(cfg['RHOST'], cfg['RPORT'], cfg['RIDENT'], cfg['RSECRET'])

    def on_message(identifier, channel, payload):
        try:
            # validate JSON
            payload = str(payload)
            rec = json.loads(payload)

            # send payload (only if its JSON validation passed)
            publisher.publish(cfg['RCHANNEL'], payload)
        except Exception as e:
            logger.exception(e)
            pass

    def on_error(payload):
        logger.error(' -> errormessage from server: {0}'.format(payload))
        subscriber.stop()
        publisher.stop()

    subscriber.subscribe([cfg['GEOLOC_CHAN']])
    try:
        subscriber.run(on_message, on_error)
    except hpfeeds.FeedException, e:
        logger.error('feed exception: %s'%e)
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
