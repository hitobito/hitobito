# Setup your system for generic wagon

Install `asdf` and `direnv` to manage versions for Ruby, Node and Yarn. See `.tool-versions` and install the currently
used versions.

Install Postgres locally or use the one from the [docker setup](https://github.com/hitobito/development/)
(`docker-compose up -d db`).
If you use a local database, create a user called "hitobito" with password "hitobito" and `createdb` and `superuser` privileges.

Clone all desired hitobito repositories (core and wagons) into a common base folder. To activate a specific wagon use
`./bin/wagon activate`, See the [Wagons documentation](04_wagons.md).

Add a `.envrc` to the base folder:

```bash
export BUNDLE_GEMFILE=Gemfile.local
export RAILS_MAIL_DELIVERY_CONFIG='address: localhost, port: 2025'
```

## Install Dependencies

Install all ruby and node dependencies (in the core folder):

    bundle install
    yarn install

## Setup Application

In the core directory:

    ./bin/active_wagon generic
    rails db:create db:migrate wagon:migrate db:seed wagon:seed dev:local:admin

## Start the application

In the core you can start with overmind:

    ./bin/dev

## Running tests

Working with `./bin/active_wagon` and the environment variables specified in
`.envrc` disables test_schema_maintainance. We do this in order to support
parallel testing of wagon and core (via distinct database). In addition we
speed up wagon test runs by removing migration overhead. As a drawback, we have
to maintain the test database schema by hand, providing the wagon tests
accordingly.

    RAILS_ENV=test rails db:migrate  # for core
    RAILS_TEST_DB_NAME=hit_generic_test RAILS_ENV=test rails db:migrate wagon:migrate

## Git Configuration

### Avoid changes in Gemfile.lock due to local wagon configuration

Copy `Gemfile` and `Gemfile.lock` to `Gemfile.local` and `Gemfile.local.lock` in order to avoid
changes in `Gemfile.lock` when wagons are configured in the local `Wagonfile`.

Set the environment variable `BUNDLE_GEMFILE=Gemfile.local` to use the alternate gemfile.

When adding or updating gems, remember to adjust the original `Gemfile` and make sure that
no local wagon configuration leaks into the updated `Gemfile.lock` when committing.

The `./bin/active_wagon` script automates that process for you if the environment variable
`BUNDLE_GEMFILE` is defined.

To ignore the `Gemfile.local` and `Gemfile.local.lock` files in all wagons you can add them to
your global gitgnore `~/.gitignore`.

### Adjusting git blame ignores

Add the following to `.git/config`

```
  [blame]
    ignoreRevsFile = .git-blame-ignore-revs
```

to ignore a very large rubocop reformatting commit
