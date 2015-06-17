"""
Clio
Mnemosyne Client Library

ThreatStream 2014
"""
import pymongo
from dateutil.parser import parse as parse_date
from collections import Counter
from bson import ObjectId, son
import json
import datetime


class Clio():
    """
    Main interface for Clio - Mnemosyne Client Library -

    Usage:

    clio = Clio()
    sessions = clio.session.get(source_ip='5.15.15.85')

    """

    def __init__(self):
        self.client = pymongo.MongoClient()

    @property
    def session(self):
        return Session(self.client)

    @property
    def counts(self):
        return Counts(self.client)

    @property
    def session_protocol(self):
        return SessionProtocol(self.client)

    @property
    def hpfeed(self):
        return HpFeed(self.client)

    @property
    def authkey(self):
        return AuthKey(self.client)

    @property
    def url(self):
        return Url(self.client)

    @property
    def file(self):
        return File(self.client)

    @property
    def dork(self):
        return Dork(self.client)

    @property
    def metadata(self):
        return Metadata(self.client)


class ResourceMixin(object):

    db_name = 'mnemosyne'
    expected_filters = ('_id',)

    def __init__(self, client=None, **kwargs):
        self.client = client
        for attr in self.__class__.expected_filters:
            setattr(self, attr, kwargs.get(attr))

    def __call__(self, *args, **kwargs):
        return self.get(*args, **kwargs)

    @classmethod
    def _clean_query(cls, dirty):
        clean = dict()
        for arg in cls.expected_filters:
            # Creating a query dictionary
            # with values passed in kwargs.
            if dirty.get(arg):
                clean[arg] = dirty.get(arg)

        if 'hours_ago' in dirty:
            clean['timestamp'] = {
                '$gte': datetime.datetime.utcnow() - datetime.timedelta(hours=int(dirty['hours_ago']))
            }

        return clean

    @classmethod
    def _clean_options(cls, opts):
        try:
            skip = int(opts.get('skip', 0))
        except (ValueError, TypeError):
            skip = 0
        limit = opts.get('limit', None)
        # If limit was not indicated, we'll leave it as 'None'.
        if limit:
            try:
                limit = int(limit)
            except (ValueError, TypeError):
                # Limit provided but wrong value,
                # give a default value.
                limit = 20
        order_by = opts.get('order_by', None)
        # If order_by wasn't passed, we'll return an empty dict.
        if order_by:
            # Figure out desired direction from order_by value.
            if order_by.startswith('-'):
                direction = pymongo.DESCENDING
            else:
                direction = pymongo.ASCENDING
            # Clean up direction from field name.
            order_by = order_by.replace('-', '')
            if order_by not in cls.expected_filters:
                # Clean up field is not valid.
                order_by = None
            else:
                # Returns the argumens needed by sort() call.
                order_by = (order_by, direction,)
        return skip, limit, order_by

    def new(self, **kwargs):
        return self.__class__.from_dict(kwargs, self.client)

    def to_dict(self):
        todict = {}
        for attr in self.__class__.expected_filters:
            todict[attr] = getattr(self, attr)

            if isinstance(todict[attr], datetime.datetime):
                todict[attr] = todict[attr].isoformat()

        # Making sure dict is json serializable.
        todict['_id'] = str(todict['_id'])
        return todict

    def get(self, options={}, **kwargs):

        if self.client is None:
            raise ValueError
        else:
            if '_id' in kwargs:
                kwargs['_id'] = ObjectId(kwargs['_id'])
                return self.__class__.from_dict(
                        self.collection.find_one(kwargs), self.client)

            query = self.__class__._clean_query(kwargs)
            queryset = self.collection.find(query)
            if options:
                skip, limit, order_by = self.__class__._clean_options(options)
                if skip:
                    queryset = queryset.skip(skip)
                if limit:
                    queryset = queryset.limit(limit)
                if order_by:
                    queryset = queryset.sort(*order_by)
            return (self.__class__.from_dict(f, self.client) for f in queryset)

    def delete(self, **kwargs):
        query = dict()
        if kwargs:
            query = self.__class__._clean_query(kwargs)
        elif self._id:
            query = {'_id': self._id}
        else:
            # Need to be at least a valid resource or
            # pass keyword arguments.
            return None
        return self.collection.remove(query)

    def count(self, **kwargs):
        query = self.__class__._clean_query(kwargs)
        # Just counting the results.
        return self.collection.find(query).count()

    @property
    def collection(self):
        """Shortcut for getting the appropriate collection object"""
        cls = self.__class__
        return self.client[cls.db_name][cls.collection_name]

    @classmethod
    def from_dict(cls, dict_, client=None):
        """
        Returns an object from a dictionary, most likely
        to come from pymongo results.
        """
        if dict_ is None:
            # Invalid dict incoming.
            return None
        doc = cls(client)
        attrs = dict_.keys()
        for at in attrs:
            # Set every key in dict_ as attribute in the object.
            setattr(doc, at, dict_.get(at))
        return doc

class Counts(ResourceMixin):
    collection_name = 'counts'
    expected_filters = ('identifier', 'date', 'event_count',)

    def get_count(self, identifier, date=None):
        query = {'identifier': identifier}
        if date:
            query['date'] = date
        return int(sum([rec['event_count'] for rec in self.collection.find(query)]))

class Session(ResourceMixin):

    collection_name = 'session'
    expected_filters = ('protocol', 'source_ip', 'source_port',
                        'destination_ip', 'destination_port',
                        'honeypot', 'timestamp', '_id', 'identifier',)

    @classmethod
    def _clean_query(cls, dirty):
        clean = super(Session, cls)._clean_query(dirty)

        def date_to_datetime(d):
            return datetime.datetime.combine(d, datetime.datetime.min.time())

        def clean_integer(field_name, query):
            # Integer fields in mongo need to be int type, GET queries
            # are passed as str so this method converts the str to
            # integer so the find() call matches properly.
            # If it's not a proper integer it will be remove
            # from the query.
            try:
                integer = int(query[field_name])
            except (ValueError, TypeError):
                query.pop(field_name)
            else:
                query[field_name] = integer
            finally:
                return query

        intfields = ('destination_port', 'source_port',)
        for field in intfields:
            if field in clean.copy():
                clean = clean_integer(field, clean)

        if 'timestamp' in clean and isinstance(clean['timestamp'], basestring):
            # Transforms timestamp queries into
            # timestamp_lte queries.
            try:
                timestamp = parse_date(clean.pop('timestamp'))
            except (ValueError, TypeError):
                pass
            else:

                clean['timestamp'] = {
                    '$gte': date_to_datetime(timestamp.date()),
                    '$lt': date_to_datetime(timestamp.date() + datetime.timedelta(days=1))
                }

        return clean

    def _tops(self, fields, top=5, hours_ago=None, **kwargs):
        if isinstance(fields, basestring):
            fields = [fields,]

        match_query = dict([ (field, {'$ne': None}) for field in fields ])

        for name, value in kwargs.items():
            if name.startswith('ne__'):
                match_query[name[4:]] = {'$ne': value}
            elif name.startswith('gt__'):
                match_query[name[4:]] = {'$gt': value}
            elif name.startswith('lt__'):
                match_query[name[4:]] = {'$lt': value}
            elif name.startswith('gte__'):
                match_query[name[5:]] = {'$gte': value}
            elif name.startswith('lte__'):
                match_query[name[5:]] = {'$lte': value}
            else:
                match_query[name] = value

        if hours_ago:
            match_query['timestamp'] = {
                '$gte': datetime.datetime.now() - datetime.timedelta(hours=hours_ago)
            }

        query = [
            {
                '$match': match_query
            },
            {
                '$group': {
                    '_id': dict( [(field, '${}'.format(field)) for field in fields] ),
                    'count': {'$sum': 1}
                }
            },
            {
                '$sort': son.SON([('count', -1)])
            }
        ]

        res = self.collection.aggregate(query)
        def format_result(r):
            result = dict(r['_id'])
            result['count'] = r['count']
            return result

        if 'ok' in res:
            return [
                format_result(r) for r in res.get('result', [])[:top]
            ]

    def top_attackers(self, top=5, hours_ago=None):
        return self._tops('source_ip', top, hours_ago)

    def top_targeted_ports(self, top=5, hours_ago=None):
        return self._tops('destination_port', top, hours_ago)

    def top_hp(self, top=5, hours_ago=None):
        return self._tops('honeypot', top, hours_ago)
    
    def top_sensor(self, top=5, hours_ago=None):
        return self._tops('identifier', top, hours_ago)
    
    def attacker_stats(self, ip, hours_ago=None):
        match_query = { 'source_ip': ip }

        if hours_ago:
            match_query['timestamp'] = {
                '$gte': datetime.datetime.now() - datetime.timedelta(hours=hours_ago)
            }

        query = [
            {
                '$match': match_query
            },
            {
                '$group': {
                    '_id': "source_ip",
                    'count': {'$sum' : 1},
                    'ports': { '$addToSet': "$destination_port"},
                    'honeypots': {'$addToSet': "$honeypot"},
                    'sensor_ids': {'$addToSet': "$identifier"},
                    'first_seen': {'$min': '$timestamp'},
                    'last_seen': {'$max': '$timestamp'},
                }
            },
            {
                '$project': {
                    "count":1,
                    'ports': 1,
                    'honeypots':1,
                    'first_seen':1,
                    'last_seen':1,
                    'num_sensors': {'$size': "$sensor_ids"}
                }
            }
        ]

        res = self.collection.aggregate(query)
        if 'ok' in res and len(res['result']) > 0:
            r = res['result'][0]
            del r['_id']
            r['first_seen'] = r['first_seen'].isoformat()
            r['last_seen'] = r['last_seen'].isoformat()
            return r

        return {
            'ip': ip,
            'count': 0,
            'ports': [],
            'honeypots': [],
            'num_sensors': 0,
            'first_seen': None,
            'last_seen': None,
        }

class SessionProtocol(ResourceMixin):

    collection_name = 'session_protocol'
    expected_filters = ('protocol', 'source_ip', 'source_port',
                        'destination_ip', 'destination_port',
                        'honeypot', '_id')


class HpFeed(ResourceMixin):

    collection_name = 'hpfeed'
    expected_filters = ('ident', 'channel', 'payload', '_id', 'timestamp', )

    channel_map = {'snort.alerts':['date', 'sensor', 'source_ip', 'destination_port', 'priority', 'classification', 'signature'],
                   'dionaea.capture':['url', 'daddr', 'saddr', 'dport', 'sport', 'sha512', 'md5'],
                   'glastopf.events':['time', 'pattern', 'filename', 'source', 'request_url']}
    def json_payload(self, data):
        if type(data) is dict:
             o_data = data
        else:
             o_data = json.loads(data)
        return o_data
        
    def get_payloads(self, options, req_args):
        payloads = []
        columns = []
        if len(req_args.get('payload','')) > 1:
            req_args['payload'] = {'$regex':req_args['payload']}

        cnt_query = super(HpFeed, self)._clean_query(req_args)
        count = self.collection.find(cnt_query).count()

        columns = self.channel_map.get(req_args['channel'])

        return count,columns,(self.json_payload(fr.payload) for fr in self.get(options=options, **req_args))


    def count_passwords(self,payloads):
        passwords=[]
        for creds in payloads:
            if creds['credentials']!= None:
                for cred in (creds['credentials']):
                    passwords.append(cred[1])
        return Counter(passwords).most_common(10)


    def count_users(self,payloads):
        users=[]
        for creds in payloads:
            if creds['credentials']!= None:
                for cred in (creds['credentials']):
                    users.append(cred[0])
        return Counter(users).most_common(10)


    def count_combos(self,payloads):
        combos_count=[]
        for combos in payloads:
            if combos['credentials']!= None:
                for combo in combos['credentials']:
                    combos_count.append(combo[0]+": "+combo[1])
        return Counter(combos_count).most_common(10)


    def _tops(self, field, chan, top=5, hours_ago=None):
        query = {'channel': chan}

        if hours_ago:
            query['hours_ago'] = hours_ago

        res = self.get(options={}, **query)
        val_list = [rec.get(field) for rec in [self.json_payload(r.payload) for r in res] if field in rec]
        cnt = Counter()
        for val in val_list:
            cnt[val] += 1
        results = [dict({field:val, 'count':num}) for val,num in cnt.most_common(top)]

        return results

    def top_sigs(self, top=5, hours_ago=24):
        return self._tops('signature', 'snort.alerts', top, hours_ago)

    def top_files(self, top=5, hours_ago=24):
        return self._tops('destination_port', top, hours_ago)

class Url(ResourceMixin):

    collection_name = 'url'
    expected_filters = ('protocol', 'source_ip', 'source_port',
                        'destination_ip', 'destination_port',
                        'honeypot', '_id')


class File(ResourceMixin):

    collection_name = 'file'
    expected_filters = ('_id', 'content_guess', 'encoding', 'hashes',)


class Dork(ResourceMixin):

    collection_name = 'dork'
    expected_filters = ('_id', 'content', 'inurl', 'lasttime', 'count',)

class Metadata(ResourceMixin):

    collection_name = 'metadata'
    expected_filters = ('ip', 'date', 'os', 'link', 'app', 'uptime', '_id', 'honeypot', 'timestamp',)


class AuthKey(ResourceMixin):

    db_name = 'hpfeeds'
    collection_name = 'auth_key'
    expected_filters = ('identifier', 'secret', 'publish', 'subscribe', '_id')

    def get(self, options={}, **kwargs):
        if 'identifier' in kwargs:
            return AuthKey.from_dict(
                    self.collection.find_one(kwargs), self.client)
        else:
            return super(AuthKey, self).get(options, **kwargs)

    def post(self):
        objectid = self.collection.insert(dict(
                identifier=self.identifier, secret=self.secret,
                publish=self.publish, subscribe=self.subscribe))
        self.client.fsync()
        return objectid

    def put(self, **kwargs):
        updated = self.collection.update({"identifier": self.identifier},
                                         {'$set': kwargs}, upsert=False)
        return updated
