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
        mhn.run(debug=config.DEBUG)

    @manager.command
    def fetch_rules():
        fetch_sources()

    manager.run()
