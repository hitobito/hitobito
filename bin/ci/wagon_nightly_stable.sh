#!/bin/env rvm-shell 1.9.3

. hitobito/bin/ci/wagon_setup.sh

bundle exec rake db:create ci:wagon --trace &&
bundle exec rake wagon:exec CMD='rake app:tarantula:test' --trace