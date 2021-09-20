#!/bin/bash

set -e

export FLASK_APP=app

# Assuming we're on local sqlite
if [[ -z "${DATABASE_URL}" ]]; then
  flask db init
  flask db migrate
  flask db upgrade
fi
flask run --host=0.0.0.0