#!/bin/bash
set -Ee
upgrade_postgres.sh "$@"
exec docker-entrypoint.sh "$@"
