ARG VERSION=17

FROM pgvector/pgvector:pg${VERSION}

RUN apt-get update && \
	apt-mark hold locales && \
	apt-get install -y --no-install-recommends pwgen && \
	apt-get autoremove -y && \
	apt-mark unhold locales && \
	rm -rf /var/lib/apt/lists/*

ADD upgrade_postgres.sh /usr/local/bin/upgrade_postgres.sh
ADD run_postgres.sh /usr/local/bin/run_postgres.sh
ADD bootstrap_db.sh /docker-entrypoint-initdb.d/bootstrap_db.sh
ENV PGDATA=/var/lib/postgresql/${VERSION}/docker \
  DB_USER=discourse \
  POSTGRES_DB=discourse
ENTRYPOINT ["run_postgres.sh"]
CMD ["postgres"]
