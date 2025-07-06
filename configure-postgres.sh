#!/bin/bash

CONFIG_FILE=${PGDATA}/postgresql.conf
if [ ! -f "${CONFIG_FILE}" ]; then
    exit 0
fi

sed -Ei "s/#?synchronous_commit *=.*/synchronous_commit = ${DB_SYNCHRONOUS_COMMIT}/" ${CONFIG_FILE}
sed -Ei "s/#?shared_buffers *=.*/shared_buffers = ${DB_SHARED_BUFFERS}/" ${CONFIG_FILE}
sed -Ei "s/#?work_mem *=.*/work_mem = ${DB_WORK_MEM}/" ${CONFIG_FILE}
sed -Ei "s/#?default_text_search_config *=.*/default_text_search_config = ${DB_DEFAULT_TEXT_SEARCH_CONFIG}/" ${CONFIG_FILE}
sed -Ei "s/#?logging_collector *=.*/logging_collector = ${DB_LOGGING_COLLECTOR}/" ${CONFIG_FILE}
sed -Ei "s/#?log_min_duration_statement *=.*/log_min_duration_statement = ${DB_LOG_MIN_DURATION_STATEMENT}/" ${CONFIG_FILE}
