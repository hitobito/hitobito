#!/bin/sh
set -e

bundle check || bundle install
bundle exec rake db:setup RAILS_ENV=test

exec "$@"

