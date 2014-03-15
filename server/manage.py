from urlparse import urlparse

from flask.ext.script import Manager
from flask.ext.migrate import Migrate, MigrateCommand

try:
    import config
except ImportError:
    print 'It seems like this is the first time running the server.'
    print 'First let us generate a proper configuration file.'
    from generateconfig import generate_config
    generate_config()
    import config
    from mhn import create_clean_db
    print 'Initializing database "{}".'.format(config.SQLALCHEMY_DATABASE_URI)
    create_clean_db()
from mhn import mhn, db
from mhn.tasks.rules import fetch_sources


if __name__ == '__main__':
    migrate = Migrate(mhn, db)
    manager = Manager(mhn)
    manager.add_command('db', MigrateCommand)

    @manager.command
    def run():
        # Takes run parameters from configuration.
        serverurl = urlparse(config.SERVER_BASE_URL)
        mhn.run(debug=config.DEBUG, host='0.0.0.0',
                port=serverurl.port)

    @manager.command
    def fetch_rules():
        fetch_sources()

    manager.run()
