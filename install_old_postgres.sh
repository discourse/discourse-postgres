#!/bin/bash
if [ ! -f /shared/postgres_data/PG_VERSION ]; then
    exit 0
fi
PG_MAJOR_OLD=`cat /shared/postgres_data/PG_VERSION`
PG_MAJOR_NEW=`postgres --version | sed -rn 's/^[^0-9]*+([0-9]++).*/\1/p'`
if [ ! "${PG_MAJOR_NEW}" = "$PG_MAJOR_OLD" ]; then
  apt-get update
  apt-get install -y postgresql-${PG_MAJOR_OLD} postgresql-${PG_MAJOR_OLD}-pgvector
fi
