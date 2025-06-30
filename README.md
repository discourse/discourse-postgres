some attempts at managing an auto-upgrade of postgres clusters

From any version. Takes the latest.

Not depending on /shared/postgres_data means we can drop a lot of the moving/shuffling around as all versions will have their own proper data dirs.

New data dirs will be initialized separately.

some notes:
* postmaster.opts file can mess up data dir... if this exists in an old cluster directory, it can overwrite env vars set to `PGDATAOLD` for pg_upgrade command.
* socket file that's created by postgres at /var/run/postgres - thus the cd.
* postgres image is in the process of using /var/lib/postgresql/{version}/docker as default data dirs (from /var/lib/postgresql/data)
* /var/lib/postgresql/data up until pg version 17 was declared a volume, so the directory just got created from whatever the parent mount was for parent volumes.
* I do not understand why postmaster.pid was deleted, nor why data_directory was being printed to postgresql.conf pre-upgrade.

See also https://github.com/docker-library/postgres/pull/1259
for recent work on data dirs for postgres image (will land in 18)
for now we need an explicit PGDATA on the image
and a mount on to `/var/lib/postgresql` rather than `/var/lib/postgresql/data`...
