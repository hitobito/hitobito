# Runs a wagon nightly build for the master branch

. hitobito/bin/ci/wagon_setup.sh

bundle exec rake db:create wagon:exec CMD="bundle exec rake app:db:test:prepare" --trace &&
bundle exec rake ci:wagon:nightly --trace &&
bundle exec rake wagon:exec CMD='rake app:tarantula:test app:tx:auth app:tx:push' --trace
