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
ENV PGDATA=/var/lib/postgresql/${VERSION}/docker \
  DB_USER=discourse \
  POSTGRES_DB=discourse \
  POSTGRES_INITDB_ARGS="--set synchronous_commit=${DB_SYNCHRONOUS_COMMIT} \
  --set shared_buffers=${DB_SHARED_BUFFERS} \
  --set work_mem=${DB_WORK_MEM} \
  --set default_text_search_config=${DB_DEFAULT_TEXT_SEARCH_CONFIG} \
  --set logging_collector=${DB_LOGGING_COLLECTOR} \
  --set log_min_duration_statement=${DB_LOG_MIN_DURATION_STATEMENT}"
ENTRYPOINT ["run_postgres.sh"]
CMD ["postgres"]
