#!/usr/bin/env bash
set -e

if [ ! -z "$DB_USER" ] && [ ! "$DB_USER" = "$POSTGRES_USER" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
CREATE USER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $DB_USER;
ALTER SCHEMA PUBLIC owner TO $DB_USER;
ALTER USER $DB_USER with password '$DB_PASSWORD';
EOSQL
fi

if [ ! "$SKIP_EXTENSIONS" = "1" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "template1" <<-EOSQL
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS vector;
ALTER EXTENSION vector UPDATE;
EOSQL

    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS vector;
ALTER EXTENSION vector UPDATE;
EOSQL
fi
