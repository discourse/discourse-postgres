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

Superuser concerns:
default install superuser also installs postgres as the superuser...
but postgres docker installs the superuser as whatever user is declared.

this has some security concerns, but also makes it a bit more difficult to move clusters between old and new, as the postgres user just doesn't exist at all in postgres docker created clusters.

initdb by default uses the current username. Usually this is run as postgres, so postgres becomes the default superuser. This is not the case with docker image... the POSTGRES_USER is.

see also https://github.com/docker-library/postgres/issues/175

also theres everything done in create_db file:
* create extensions on schema
* database encoding

bootstrap_db.sh creates the extensions to the db, and adds the owning (non super) user with:
POSTGRES_USER_NOT_SUPER
POSTGRES_PASSWORD_NOT_SUPER
