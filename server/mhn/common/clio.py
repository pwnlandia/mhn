"""
Clio
Mnemosyne Client Library

ThreatStream 2014
"""
import pymongo

from bson import ObjectId


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


class ResourceMixin(object):

    db_name = 'mnemosyne'
    expected_filters = ()

    def __init__(self, client=None, **kwargs):
        self.client = client
        for attr in self.__class__.expected_filters:
            setattr(self, attr, kwargs.get(attr))

    def new(self, **kwargs):
        return self.__class__.from_dict(kwargs, self.client)

    def to_dict(self):
        todict = {}
        for attr in self.__class__.expected_filters:
            todict[attr] = getattr(self, attr)
        return todict

    def get(self, **kwargs):
        if self.client is None:
            raise ValueError
        else:
            query = dict()
            if '_id' in kwargs:
                kwargs['_id'] = ObjectId(kwargs['_id'])
                return self.__class__.from_dict(
                        self.collection.find_one(kwargs), self.client)
            for arg in self.expected_filters:
                # Creating a query dictionary
                # with values passed in kwargs.
                if kwargs.get(arg):
                    query[arg] = kwargs.get(arg)
            queryset = self.collection.find(query)
            return (self.__class__.from_dict(f, self.client) for f in queryset)

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


class Session(ResourceMixin):

    collection_name = 'session'
    expected_filters = ('protocol', 'source_ip', 'source_port',
                        'destination_ip', 'destination_port',
                        'honeypot')


class SessionProtocol(ResourceMixin):

    collection_name = 'session_protocol'
    expected_filters = ('protocol', 'source_ip', 'source_port',
                        'destination_ip', 'destination_port',
                        'honeypot')


class HpFeed(ResourceMixin):

    collection_name = 'hpfeed'
    expected_filters = ('ident', 'channel', 'last_error', 'last_error_timestamp',
                        'normalized', 'payload')


class Url(ResourceMixin):

    collection_name = 'url'
    expected_filters = ('protocol', 'source_ip', 'source_port',
                        'destination_ip', 'destination_port',
                        'honeypot')


class File(ResourceMixin):

    collection_name = 'file'
    expected_filters = ('md5', 'sha1', 'sha512')


class AuthKey(ResourceMixin):

    db_name = 'hpfeeds'
    collection_name = 'auth_key'
    expected_filters = ('identifier', 'secret', 'publish', 'subscribe')

    def get(self, **kwargs):
        if 'identifier' in kwargs:
            return AuthKey.from_dict(
                    self.collection.find_one(kwargs), self.client)
        else:
            return super(AuthKey, self).get(**kwargs)

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

