# Setup your system for generic wagon

Install `asdf` and `direnv` to manage versions for Ruby, Node and Yarn. See `.tool-versions` and install the currently
used versions.

Install Postgres locally or use the one from the [docker setup](https://github.com/hitobito/development/)
(`docker-compose up -d db`).

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

    ./bin/wagon activate generic
    rails db:create db:migrate wagon:migrate db:seed wagon:seed dev:local:admin

## Start the application

In the core you can start with overmind

    ./bin/dev

## Adjusting git blame ignores

Add the following to `.git/config`

```
  [blame]
    ignoreRevsFile = .git-blame-ignore-revs
```

to ignore a very large rubocop reformatting commit
