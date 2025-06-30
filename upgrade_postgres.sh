#!/bin/bash
set -Eeuo pipefail
if [ ! -f /shared/postgres_data/PG_VERSION ]; then
    exit 0
fi

source /usr/local/bin/docker-entrypoint.sh
docker_setup_env
docker_create_db_directories

PG_MAJOR_OLD=`cat /shared/postgres_data/PG_VERSION`
PG_MAJOR_NEW=`postgres --version | sed -rn 's/^[^0-9]*+([0-9]++).*/\1/p'`

if [ "$(id -u)" = '0' ]; then
	  # install old postgres then restart script as postgres user
    if [ ! "${PG_MAJOR_NEW}" = "$PG_MAJOR_OLD" ]; then
        apt-get update
        apt-get install -y postgresql-${PG_MAJOR_OLD} postgresql-${PG_MAJOR_OLD}-pgvector
    fi
	  exec gosu postgres "$BASH_SOURCE" "$@"
fi

if [ ! "${PG_MAJOR_NEW}" = "$PG_MAJOR_OLD" ]; then
  echo Upgrading PostgreSQL from version ${PG_MAJOR_OLD} to ${PG_MAJOR_NEW}
  free_disk=$(df -P -B1 /shared | tail -n 1 | awk '{print $4}')
  required=$(($(du -sb /shared/postgres_data | awk '{print $1}') * 2))

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

  if [ -d /shared/postgres_data_old ]; then
    mv /shared/postgres_data_old /shared/postgres_data_older
  fi

  rm -fr /shared/postgres_data_new
  PGDATA=/shared/postgres_data_new
	docker_init_database_dir
	pg_setup_hba_conf "$@"
  #chown -R postgres:postgres /var/lib/postgresql/${PG_MAJOR_NEW}
  #/etc/init.d/postgresql stop
  #rm -fr /shared/postgres_data/postmaster.pid
  cd ~postgres
  #cp -pr /etc/postgresql/${PG_MAJOR_OLD}/main/* /shared/postgres_data
  echo  >> /shared/postgres_data/postgresql.conf
  echo "data_directory = '/shared/postgres_data'" >> /shared/postgres_data/postgresql.conf
  SUCCESS=true
  /usr/lib/postgresql/${PG_MAJOR_NEW}/bin/pg_upgrade --username="$POSTGRES_USER" -d /shared/postgres_data -D /shared/postgres_data_new -b /usr/lib/postgresql/${PG_MAJOR_OLD}/bin -B /usr/lib/postgresql/${PG_MAJOR_NEW}/bin || SUCCESS=false

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

  mv /shared/postgres_data /shared/postgres_data_old
  mv /shared/postgres_data_new /shared/postgres_data

  echo -------------------------------------------------------------------------------------
  echo UPGRADE OF POSTGRES COMPLETE
  echo
  echo Old ${PG_MAJOR_OLD} database is stored at /shared/postgres_data_old
  echo
  echo To complete the upgrade, rebuild again using:
  echo
  echo     ./launcher rebuild app
  echo -------------------------------------------------------------------------------------
  # Magic exit status to denote no failure
  exit 77
fi
