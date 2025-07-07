#!/bin/bash
set -Ee

if [ -z "$DB_PASSWORD" ]; then
    echo "Error: DB_PASSWORD not set."
    exit 1
fi
# Generate a password if one is not provided
if [ -z "$POSTGRES_PASSWORD" ]; then
    export POSTGRES_PASSWORD=$(pwgen -cnys 20 1)
fi

# Generate locales
if [ ! -z "$LANG" ] && [ "$LANG" != "en_US.utf8" ]; then
    sed -i "s/^# $LANG/$LANG/" /etc/locale.gen
    locale-gen && update-locale
fi

# Configure postgresql.conf file on
# * existing database (same version)
# * existing database (upgrading version)
# * new database (called by docker-entrypoint)
/docker-entrypoint-initdb.d/configure-postgres.sh
upgrade-postgres.sh "$@"
exec docker-entrypoint.sh "$@"
