from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
import os
import socket

basedir = os.path.abspath(os.path.dirname(__file__))


class Config(object):
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'bleh'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///' + os.path.join(basedir, 'app.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False


db = SQLAlchemy()
migrate = Migrate()


def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    from . import models

    db.init_app(app)
    migrate.init_app(app, db)

    from . import notes
    app.register_blueprint(notes.bp)
    app.add_url_rule('/', endpoint='index')

    @app.context_processor
    def utility_processor():
        def hostname():
            return socket.gethostname()

        return dict(hostname=hostname)

    return app






