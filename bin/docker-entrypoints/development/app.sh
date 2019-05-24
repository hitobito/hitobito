#!/bin/sh
set -e

[ ! -e /app/tmp/pids/server.pid ] || rm /app/tmp/pids/server.pid
bundle check || bundle install
bundle exec rake db:migrate || bundle exec rake db:setup:all RAILS_ENV=$RAILS_ENV

exec "$@"

