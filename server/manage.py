from flask.ext.script import Manager
from flask.ext.migrate import Migrate, MigrateCommand

import config
from mhn import mhn, db


if __name__ == '__main__':
    migrate = Migrate(mhn, db)
    manager = Manager(mhn)
    manager.add_command('db', MigrateCommand)

    @manager.command
    def run():
        mhn.run(debug=config.DEBUG)

    manager.run()
