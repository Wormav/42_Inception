#!/bin/bash

echo "Hello, I am Jeremy Lorette. I certify that this image is custom."

if [ -f /docker-entrypoint-initdb.d/init.sql.template ]; then
  envsubst < /docker-entrypoint-initdb.d/init.sql.template > /etc/mysql/init.sql
  rm /docker-entrypoint-initdb.d/init.sql.template
fi

exec "$@"
