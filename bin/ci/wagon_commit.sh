# Runs a wagon commit build

. hitobito/bin/ci/wagon_setup.sh

bundle exec rake db:create wagon:exec CMD="bundle exec rake app:db:test:prepare" --trace &&
bundle exec rake ci:wagon --trace