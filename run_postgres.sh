#!/bin/bash
set -Ee
install_old_postgres.sh "$@"
upgrade_postgres.sh "$@"
exec docker-entrypoint.sh "$@"
