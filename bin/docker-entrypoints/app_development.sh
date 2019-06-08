#!/bin/sh
set -e

[ ! -e /app/tmp/pids/server.pid ] || rm /app/tmp/pids/server.pid
bundle check || bundle install
[ ! -e /app/Wagonfile ] || rake wagon:file && bundle install

exec "$@"

