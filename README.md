# Discourse DB

Managing a postgres cluster for discourse

## Usage

This image expects data to be mounted at `/var/lib/postgresql`

Until postgres version 18, it is good to also mount a `/var/lib/postgresql/data` subdirectory as well to prevent volume leaking.

### Example

Within docker-compose, this can look like:
```
  db:
    image: featheredtoast/discourse-db
    volumes:
      - ./shared/db:/var/lib/postgresql
      - ./shared/db/data:/var/lib/postgresql/data
    environment:
      DB_PASSWORD: SOME_SECRET
```

## Features

### Auto upgrade

Some attempts at managing an auto-upgrade of postgres clusters

Upgrades from any previous version. Takes the latest.

This project stores in `/var/lib/postgres/{version}/docker` by default, to mirror the official postgres docker image's upcoming changes in postgres 18.

Keeping separate dirs in separate versions means that old data is not modified or moved out of the way for a future cluster, and older clusters do not conflict.

### Extensions

This image adds the `hstore`, `pgtrgm`, and `vector` extensions to the created database automatically.

This happens by default. If you'd like to use this DB for only non-superuser + auto DB upgrade features, you can disable this by setting `SKIP_EXTENSIONS=1`

### Language/Locales

Base postgres image expects lang to be built into the image, but this image also accepts LANG of the form `de_DE.UTF-8`, and updates lang dynamically for ease of use.

## Migrating

Migrating from Discourse single or two container involves moving/renaming the `/shared/postgres_data` folder to `/shared/{version}/docker`

New data dirs will be initialized separately.

## Env vars

This updates a few base env vars:
* `POSTGRES_DB` defaults to discourse
* `PGDATA` defaults to `/var/lib/postgresql/${VERSION}/docker` where `${VERSION}` is the postgres version, eg, `15`. This will be default behavior starting in postgres 18.

Unlike the base image, `POSTGRES_PASSWORD` can be left unset, and a random password will be generated for it.

In addition to the base postgres image env vars, this image exposes:

* `DB_USER`: the user (not superuser) account for the DB. Default `discourse`.
* `DB_PASSWORD`: the password for the user account. The image will not start if this is blank.

And exposes some additional configuration options for postgres:

`DB_SYNCHRONOUS_COMMIT`
`DB_SHARED_BUFFERS`
`DB_WORK_MEM`
`DB_DEFAULT_TEXT_SEARCH_CONFIG`
`DB_LOGGING_COLLECTOR`
`DB_LOG_MIN_DURATION_STATEMENT`

## Implementation notes

This image extends the official pgvector image which in turn extends the official postgres image.

### Running

This image starts `run-postgres.sh` which eventually hooks into the base postgres docker initialization by way of `docker-entrypoint.sh`, but first it configures postgresql.conf (if exists), and attempts to upgrade old versions of postgres (if applicable).

`bootstrap-db.sh` creates the extensions to the db, and adds the owning (non super) user with:
`DB_USER`
`DB_PASSWORD`

The user and password gets created/set on every build through launcher-built images, whereas on postgres images, they do not. This image follows postgres, and does not re-create and re-set the password on each invocation. Changing a password cannot be done by simply updating the env var.

runs `locale-gen` and `update-locale` dynamically on boot.

### Upgrading

Remove old postmaster.ops before running `pg_upgrade`: Core Discourse executes postgres differently, which generates a postmaster.opts file with arguments. This file can overwrite env vars set to `$PGDATAOLD` for `pg_upgrade` command, so we need to remove the file before upgrading.

For upgrading, the socket file is created by postgres at current directory - set to `var/run/postgres`.

In the current Discourse postgres template, I do not understand why postmaster.pid was deleted, nor why data_directory was being printed to postgresql.conf pre-upgrade. This behavior has not been replicated here.

Postgres image is in the process of using `/var/lib/postgresql/{version}/docker` as default data dirs (from /var/lib/postgresql/data):
`/var/lib/postgresql/data` up until pg version 17 was declared a volume, so the directory just got created from whatever the parent mount was for parent volumes.
Apparently pg18 will change to be `/var/lib/postgresql` but until that version, a new volume will be created for `/data`.

See also https://github.com/docker-library/postgres/pull/1259
for recent work on data dirs for postgres image (will land in 18)
For now we need an explicit PGDATA on the image
and a mount on to `/var/lib/postgresql` rather than `/var/lib/postgresql/data`...

Superuser concerns: default install superuser installs the postgres user as the superuser, but postgres docker installs the superuser as whatever user is declared.
For upgrading, `POSTGRES_USER` should remain unset and inherit the default `postgres`.
This image exposes env vars for `DB_USER` and `DB_PASSWORD` to install as non-superuser. By default `DB_USER` is `discourse`.

initdb by default uses the current username. Usually this is run as postgres, so postgres becomes the default superuser. This is not the case with docker image... the `POSTGRES_USER` is. For this reason it's good to leave this as default.

see also https://github.com/docker-library/postgres/issues/175

Migrating data from standalone/2container setups (or back again) expect `postgres` to be superuser.

## TODO

### Do we need to update encoding?
utf8 seems to be the default these days. Perhaps was used to update some really ancient versions.

