ARG VERSION=17

FROM pgvector/pgvector:pg${VERSION}
ARG VERSION
ARG DB_SYNCHRONOUS_COMMIT=off
ARG DB_SHARED_BUFFERS=256MB
ARG DB_WORK_MEM=10MB
ARG DB_DEFAULT_TEXT_SEARCH_CONFIG=pg_catalog.english
ARG DB_LOGGING_COLLECTOR=off
ARG DB_LOG_MIN_DURATION_STATEMENT=100

RUN apt-get update && \
	apt-mark hold locales && \
	apt-get install -y --no-install-recommends pwgen && \
	apt-get autoremove -y && \
	apt-mark unhold locales && \
	rm -rf /var/lib/apt/lists/*

ADD upgrade-postgres.sh /usr/local/bin/upgrade-postgres.sh
ADD run-postgres.sh /usr/local/bin/run-postgres.sh
ADD bootstrap-db.sh /docker-entrypoint-initdb.d/bootstrap-db.sh
ADD configure-postgres.sh /docker-entrypoint-initdb.d/configure-postgres.sh
ENV PGDATA=/var/lib/postgresql/${VERSION}/docker \
  POSTGRES_USER=postgres \
  DB_USER=discourse \
  POSTGRES_DB=discourse \
  DB_SYNCHRONOUS_COMMIT=${DB_SYNCHRONOUS_COMMIT} \
  DB_SHARED_BUFFERS=${DB_SHARED_BUFFERS} \
  DB_WORK_MEM=${DB_WORK_MEM} \
  DB_DEFAULT_TEXT_SEARCH_CONFIG=${DB_DEFAULT_TEXT_SEARCH_CONFIG} \
  DB_LOGGING_COLLECTOR=${DB_LOGGING_COLLECTOR} \
  DB_LOG_MIN_DURATION_STATEMENT=${DB_LOG_MIN_DURATION_STATEMENT}
ENTRYPOINT ["run-postgres.sh"]
CMD ["postgres"]
