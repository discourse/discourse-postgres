ARG PG_VERSION=17

FROM pgvector/pgvector:PG${PG_VERSION}
ADD upgrade_postgres /usr/local/bin/upgrade_postgres
ADD run_postgres /usr/local/bin/run_postgres
# TODO: change entrypoint
ENTRYPOINT run_postgres
