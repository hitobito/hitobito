# Setup your system

Install `asdf` and `direnv` to manage versions for Ruby, Node and Yarn. See `.tool-versions` and install the currently used versions.

Install MySql 5.7 locally or use the one from the [docker setup](https://github.com/hitobito/development/) (`docker-compose up -d db`).

Clone all desired hitobito repositories (core and wagons) into a common base folder. Adjust your `Wagonfile` in the core. See the [Wagons documentation](04_wagons.md).

Add a `.envrc` to the base folder:

```bash
export RAILS_DB_ADAPTER=mysql2
export RAILS_DB_USERNAME=hitobito
export RAILS_DB_PASSWORD=hitobito
export RAILS_DB_HOST=127.0.0.1
export RAILS_DB_PORT=33066
export RAILS_DB_NAME=hitobito_development
export RAILS_TEST_DB_NAME=hitobito_test

export RAILS_MAIL_DELIVERY_CONFIG='address: localhost, port: 2025'
export RAILS_MAIL_DELIVERY_METHOD=smtp
export RAILS_MAIL_DOMAIN=localhost

export HITOBITO_DEV_PASSWORD=hito42bito
```

## Install Dependencies

Install all ruby and node dependencies (in the core folder):

    bundle install
    yarn install

## Setup Database

In the core directory (`rails db:schema:load` might be currently broken):

    rails db:migrate
    rails wagon:migrate
    rails db:seed
    rails wagon:seed

## Server

In the core directory, in two separate shells:

    rails s
    bin/webpack-dev-server

Login on http://localhost:3000 with the root email (see `wagon/config/settings.yml`) and the password set in `HITOBITO_DEV_PASSWORD`.
