from flask.ext.script import Manager
from flask.ext.migrate import Migrate, MigrateCommand

import config
from mhn import create_app, db


if __name__ == '__main__':
    app = create_app()
    migrate = Migrate(app, db)
    manager = Manager(app)
    manager.add_command('db', MigrateCommand)

    @manager.command
    def run():
        app.run(debug=config.DEBUG)

    manager.run()
