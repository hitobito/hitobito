# Runs a wagon commit build

. hitobito/bin/ci/wagon_setup.sh

bundle exec rake db:create db:test:prepare --trace &&
bundle exec ci:wagon --trace