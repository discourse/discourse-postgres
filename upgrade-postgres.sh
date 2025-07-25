#!/bin/bash
set -Eeuo pipefail
# exit early if no data dirs exist
find /var/lib/postgresql -maxdepth 3 -type f -name PG_VERSION | grep . > /dev/null || exit 0

source /usr/local/bin/docker-entrypoint.sh
docker_setup_env

# assume we're upgrading from latest found pg major dir
# and the entire cluster mount is expected to go to /var/lib/postgresql
# per https://github.com/docker-library/postgres/pull/1259

# Of the form `{PGDATAOLD} {PG_MAJOR_OLD}` - saves the newest 'old' version found
PGDATAOLD_AND_PG_MAJOR_OLD=$(find /var/lib/postgresql -maxdepth 3 -type f -name PG_VERSION | xargs -I % sh -c 'printf "% "; cat %' | sort -nk2,2 | tail -n1 | sed 's/\/PG_VERSION//')
PG_MAJOR_OLD=$(echo $PGDATAOLD_AND_PG_MAJOR_OLD | awk '{print $2}')
PG_MAJOR_NEW=$(postgres --version | sed -rn 's/^[^0-9]*+([0-9]++).*/\1/p')

# exit if pg major cluster exists
if [ "${PG_MAJOR_NEW}" = "$PG_MAJOR_OLD" ]; then
    exit 0
fi
# exit with warning if pg major cluster exceeds current version
if [ "${PG_MAJOR_NEW}" -lt "$PG_MAJOR_OLD" ]; then
    echo "WARNING: old DB is newer postgres version, current DB is ${PG_MAJOR_NEW}, old version is ${PG_MAJOR_OLD}!"
    exit 1
fi

docker_create_db_directories
export PGDATAOLD=$(echo $PGDATAOLD_AND_PG_MAJOR_OLD | awk '{print $1}')
export PGDATANEW=${PGDATA}
export PGBINOLD=/usr/lib/postgresql/${PG_MAJOR_OLD}/bin
export PGBINNEW=/usr/lib/postgresql/${PG_MAJOR_NEW}/bin

if [ "$(id -u)" = '0' ]; then
	  # install old postgres then restart script as postgres user
    echo "Installing PostgreSQL version ${PG_MAJOR_OLD} for upgrade.."
    apt-get update
    apt-get install -y postgresql-${PG_MAJOR_OLD} postgresql-${PG_MAJOR_OLD}-pgvector
    echo "Fixing permissions in ${PGDATAOLD}..."
		find "$PGDATAOLD" \! -user postgres -exec chown postgres '{}' +
	  exec gosu postgres "$BASH_SOURCE" "$@"
fi

echo Upgrading PostgreSQL from version ${PG_MAJOR_OLD} to ${PG_MAJOR_NEW}
free_disk=$(df -P -B1 /var/lib/postgresql | tail -n 1 | awk '{print $4}')
required=$(($(du -sb ${PGDATAOLD} | awk '{print $1}') * 2))

if [ "$free_disk" -lt "$required" ]; then
  echo
  echo -------------------------------------------------------------------------------------
  echo "WARNING: Upgrading PostgreSQL would require an additional $(numfmt --to=si $(($required - $free_disk))) of disk space"
  echo "Please free up some space, or expand your disk, before continuing."
  echo
  echo -------------------------------------------------------------------------------------
  exit 1
fi

docker_init_database_dir
/docker-entrypoint-initdb.d/configure-postgres.sh
pg_setup_hba_conf "$@"
cd /var/run/postgresql
SUCCESS=true

rm -fr ${PGDATAOLD}/postmaster.pid
rm -fr ${PGDATAOLD}/postmaster.opts
${PGBINNEW}/pg_upgrade --username="$POSTGRES_USER" || SUCCESS=false

if [[ "$SUCCESS" == 'false' ]]; then
  echo -------------------------------------------------------------------------------------
  echo UPGRADE OF POSTGRES FAILED
  echo
  echo -------------------------------------------------------------------------------------
  exit 1
fi

echo "PostgreSQL version ${PG_MAJOR_OLD} upgrade complete"
exit 0
