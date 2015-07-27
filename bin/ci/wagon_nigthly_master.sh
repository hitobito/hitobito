#!/bin/env rvm-shell 1.9.3

. hitobito/bin/ci/wagon_setup.sh

bundle exec rake db:create ci:wagon:nightly --trace &&
bundle exec rake wagon:exec CMD='rake app:tarantula:test app:tx:auth app:tx:push' --trace