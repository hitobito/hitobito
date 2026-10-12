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

### Fixtures and Seeds

Before the suite runs, the test database is prepared once by `TestDatabase.prepare`
(`spec/support/test_database.rb`), called in a `before(:suite)` hook of the core `spec_helper`:

1. All tables are truncated (except `schema_migrations` and `ar_internal_metadata`), so every run
   starts from the same state.
2. All fixtures of `config.fixture_paths` are loaded.
3. The seeds registered in `config.seeds` are loaded.

Fixtures and seeds are committed and survive the rollback after each example.

The fixtures must be loaded before the seeds: loading fixtures deletes all rows of every table
having a fixture file (e.g. `action_text_rich_texts`), which would wipe seeded data stored there.
Loaded in `before(:suite)`, the fixture sets are cached, so the fixture setup of the examples does
not delete anything anymore.

Wagons (or the core) needing seeded data in their specs, e.g. custom contents, register the seeds
in their `spec_helper`. Each entry is passed to `SeedFu.seed(paths, filter)`:

```ruby
RSpec.configure do |config|
  config.fixture_paths = [File.expand_path("fixtures", __dir__)]

  config.seeds << {
    paths: [
      Rails.root.join("db", "seeds"),
      HitobitoMyWagon::Wagon.root.join("db", "seeds")
    ],
    filter: /custom_contents/
  }
end
```

Things to keep in mind:

* Never load seeds when the spec files are required (e.g. a plain `SeedFu.seed` in
  `spec/support`). They are truncated before the suite starts.
* Seeds are loaded in addition to the fixtures, they do not replace them. Use `filter` to load only
  the seed files actually needed, preferably for tables without fixtures. Otherwise e.g. the root
  person from `db/seeds/root.rb` ends up next to the fixture people.
* Data inserted by migrations during `db:test:prepare` is truncated as well.
* Never run two spec processes against the same test database concurrently.
* Specs without transactional fixtures reload the fixtures, which wipes seeded data in tables
  having fixtures again.
