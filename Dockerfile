ARG VERSION=pg17

FROM pgvector/pgvector:${VERSION}

ADD upgrade_postgres.sh /usr/local/bin/upgrade_postgres.sh
ADD run_postgres.sh /usr/local/bin/run_postgres.sh
ENTRYPOINT ["run_postgres.sh"]
CMD ["postgres"]
