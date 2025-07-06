ARG VERSION=17

FROM pgvector/pgvector:pg${VERSION}
ARG VERSION
ARG DB_SYNCHRONOUS_COMMIT=off
ARG DB_SHARED_BUFFERS=256MB
ARG DB_WORK_MEM=10MB
ARG DB_DEFAULT_TEXT_SEARCH_CONFIG=pg_catalog.english
ARG DB_CHECKPOINT_SEGMENTS=6
ARG DB_LOGGING_COLLECTOR=off
ARG DB_LOG_MIN_DURATION_STATEMENT=100

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
  POSTGRES_DB=discourse \
  POSTGRES_INITDB_ARGS="--set synchronous_commit=${DB_SYNCHRONOUS_COMMIT} \
  --set shared_buffers=${DB_SHARED_BUFFERS} \
  --set work_mem=${DB_WORK_MEM} \
  --set default_text_search_config=${DB_DEFAULT_TEXT_SEARCH_CONFIG} \
  --set checkpoint_segments=${DB_CHECKPOINT_SEGMENTS} \
  --set logging_collector=${DB_LOGGING_COLLECTOR} \
  --set log_min_duration_statement=${DB_LOG_MIN_DURATION_STATEMENT}"
ENTRYPOINT ["run_postgres.sh"]
CMD ["postgres"]
