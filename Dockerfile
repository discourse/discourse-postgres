ARG VERSION=pg17

FROM pgvector/pgvector:${VERSION}

ADD upgrade_postgres.sh /usr/local/bin/upgrade_postgres.sh
ADD run_postgres.sh /usr/local/bin/run_postgres.sh
ADD bootstrap_db.sh /docker-entrypoint-initdb.d/bootstrap_db.sh
ENTRYPOINT ["run_postgres.sh"]
CMD ["postgres"]
