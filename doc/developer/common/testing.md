## Testing

🚢 If your are developing with docker, the following command must be executed in the `rails-test` container console: `docker-compose exec rails-test bash`.

Because tests for the core and for the wagons use the same database, but potentially have diverging schemas, make sure to always prepare the test database before switching between core and a wagon.

Prepare the test database:

    rails db:test:prepare       # in core directory
    rails app:db:test:prepare   # in wagon directory

Run tests:

    rails spec:without_features
    bin/rspec spec/../file_spec.rb:42

Run feature tests:

    bin/webpack-test-compile
    rails spec:features
    bin/rspec --tag type:feature spec/features/role_lists_controller_spec.rb

If you experience problems with asset requests, make sure that the Webpack Dev Server is not running and clean up the existing assets with `rm -rf public/packs*`, then run `bin/webpack-test-compile` again.

For performance reasons, logging is disabled in test env. If you need logging for debugging, activate it by:

    DISABLE_SPRING=1 LOG=all bin/rspec spec/controllers/addresses_controller_spec.rb

### Using `active_wagon` Script

Working with `./bin/active_wagon` and the environment variables specified in
`.envrc` disables test_schema_maintainance. We do this in order to support
parallel testing of wagon and core (via distinct database). In addition we
speed up wagon test runs by removing migration overhead. As a drawback, we have
to maintain the test database schema by hand, providing the wagon tests
accordingly.

    RAILS_ENV=test rails db:migrate  # for core
    RAILS_TEST_DB_NAME=hit_generic_test RAILS_ENV=test rails db:migrate wagon:migrate
