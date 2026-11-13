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

    bin/active_wagon generic
    rails db:create db:migrate wagon:migrate db:seed wagon:seed dev:local:admin

## Start the application

In the core you can start with overmind:

    bin/dev

## Running tests

See [Testing](./common/testing.md).

## Git Configuration

### Avoid changes in Gemfile.lock due to local wagon configuration

Wagons configured in the local `Wagonfile` are written into `Gemfile.lock`, leaving unwanted changes
in the working tree. To avoid this, set `BUNDLE_GEMFILE=Gemfile.local` and bundler uses
`Gemfile.local.lock` instead. The catch: the two lockfiles can drift apart, and a working local
lockfile hides a broken `Gemfile.lock`, which is the one CI uses.

So when adding or updating gems, unset `BUNDLE_GEMFILE` and `WAGONS`, e.g.
`env -u BUNDLE_GEMFILE WAGONS= bundle update <gem> --conservative`, and commit `Gemfile.lock`.

`./bin/active_wagon` then links `Gemfile.local` to `Gemfile` and copies `Gemfile.lock` to
`Gemfile.local.lock` in the core and the active wagons, so the local lockfiles start from the
committed ones again.

To ignore the `Gemfile.local` and `Gemfile.local.lock` files in all wagons you can add them to
your global gitignore `~/.gitignore`.

### Adjusting git blame ignores

Add the following to `.git/config`

```
  [blame]
    ignoreRevsFile = .git-blame-ignore-revs
```

to ignore a very large rubocop reformatting commit
