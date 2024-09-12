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

For performance reasons, loggin is disabled in test env. If you need logging for debugging, active it by:

    DISABLE_SPRING=1 LOG=all bin/rspec spec/controllers/addresses_controller_spec.rb
