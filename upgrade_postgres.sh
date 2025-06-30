#!/bin/bash
set -Eeuo pipefail
# exit early if no data dirs exist
find /var/lib/postgresql -name PG_VERSION -maxdepth 3 -type f | grep . > /dev/null || exit 0

source /usr/local/bin/docker-entrypoint.sh
docker_setup_env
docker_create_db_directories

# assume we're upgrading from latest found pg major dir
# data dir/cluster name is /docker, so data is expected at /var/lib/postgres/{version}/docker/*
# and the entire cluster mount is expected to go to /var/lib/postgresql
# per https://github.com/docker-library/postgres/pull/1259
PG_MAJOR_OLD=`find /var/lib/postgresql -name PG_VERSION -maxdepth 3 -type f -exec cat {} \; | sort -n | tail -n 1`
PG_MAJOR_NEW=`postgres --version | sed -rn 's/^[^0-9]*+([0-9]++).*/\1/p'`
export PGDATAOLD=/var/lib/postgresql/${PG_MAJOR_OLD}/docker
export PGDATANEW=${PGDATA}
export PGBINOLD=/usr/lib/postgresql/${PG_MAJOR_OLD}/bin
export PGBINNEW=/usr/lib/postgresql/${PG_MAJOR_NEW}/bin

if [ "$(id -u)" = '0' ]; then
	  # install old postgres then restart script as postgres user
    if [ ! "${PG_MAJOR_NEW}" = "$PG_MAJOR_OLD" ]; then
        echo "Installing PostgreSQL version ${PG_MAJOR_OLD} for upgrade.."
        apt-get update
        apt-get install -y postgresql-${PG_MAJOR_OLD} postgresql-${PG_MAJOR_OLD}-pgvector
    fi
	  exec gosu postgres "$BASH_SOURCE" "$@"
fi

if [ ! "${PG_MAJOR_NEW}" = "$PG_MAJOR_OLD" ]; then
  echo Upgrading PostgreSQL from version ${PG_MAJOR_OLD} to ${PG_MAJOR_NEW}
  free_disk=$(df -P -B1 /var/lib/postgresql | tail -n 1 | awk '{print $4}')
  required=$(($(du -sb /var/lib/postgresql/${PG_MAJOR_OLD}/docker | awk '{print $1}') * 2))

  if [ "$free_disk" -lt "$required" ]; then
    echo
    echo -------------------------------------------------------------------------------------
    echo "WARNING: Upgrading PostgreSQL would require an additional $(numfmt --to=si $(($required - $free_disk))) of disk space"
    echo "Please free up some space, or expand your disk, before continuing."
    echo
    echo 'To avoid upgrading change "templates/postgres.template.yml" TO "templates/postgres.13.template.yml" in containers/app.yml'
    echo
    echo 'You can run "./launcher start app" to restart your app in the meanwhile.'
    echo -------------------------------------------------------------------------------------
    exit 1
  fi

	docker_init_database_dir
	pg_setup_hba_conf "$@"
  cd /var/run/postgresql
  SUCCESS=true
  ${PGBINNEW}/pg_upgrade --username="$POSTGRES_USER" || SUCCESS=false

  if [[ "$SUCCESS" == 'false' ]]; then
    echo -------------------------------------------------------------------------------------
    echo UPGRADE OF POSTGRES FAILED
    echo
    echo Please visit https://meta.discourse.org/t/postgresql-15-update/349515 for support.
    echo
    echo You can run "./launcher start app" to restart your app in the meanwhile
    echo -------------------------------------------------------------------------------------
    exit 1
  fi

  echo -------------------------------------------------------------------------------------
  echo UPGRADE OF POSTGRES COMPLETE
  echo
  echo Old ${PG_MAJOR_OLD} database is stored at /shared/postgres/${PG_MAJOR_OLD}/docker
  echo
  echo To complete the upgrade, rebuild again using:
  echo
  echo     ./launcher rebuild app
  echo -------------------------------------------------------------------------------------
  # Magic exit status to denote no failure
  exit 77
fi
