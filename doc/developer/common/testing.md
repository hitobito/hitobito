## Testing

Prepare the test database and build the assets the test environment needs, once per directory,
in the core directory for core specs and in the wagon directory for that wagon's specs:

    bin/rails db:test:prepare

The test database name is derived from the directory, so core and wagon specs do not interfere.
The assets are built into `app/assets/builds/<composition>`, `core` for the core specs and the wagon
composition for a wagon's specs. To skip the asset build, for example when only running model specs,
set `SKIP_CSS_BUILD=1 SKIP_JS_BUILD=1`. To rebuild only the assets:

    bin/rails assets:build_for_test       # in core directory
    bin/rails app:assets:build_for_test   # in wagon directory

Run tests:

    rails spec:without_features
    bin/rspec spec/../file_spec.rb:42

Run feature tests:

    rails spec:features
    bin/rspec --tag type:feature spec/features/role_lists_controller_spec.rb

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
