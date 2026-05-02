#!/bin/bash
set -e

# Start postgres in the background to initialize the DB
/usr/lib/postgresql/13/bin/postgres -D /var/lib/postgresql/13/main -c config_file=/etc/postgresql/13/main/postgresql.conf &
pid="$!"

sleep 5 # Wait for DB to start

# Run the exact commands from your old bash script
psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';" || true
psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};" || true
psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};" || true

# Bring the background process to the foreground so the container stays alive
wait "$pid"