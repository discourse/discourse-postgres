#!/bin/bash
set -Ee

if [ -z "$DB_PASSWORD" ]; then
    echo "DB_PASSWORD not set."
    exit 1
fi
# Generate a password if one is not provided
if [ -z "$POSTGRES_PASSWORD" ]; then
    export POSTGRES_PASSWORD=$(pwgen -cnys 20 1)
fi
upgrade-postgres.sh "$@"
exec docker-entrypoint.sh "$@"
