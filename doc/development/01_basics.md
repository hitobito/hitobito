## Development

### Setup

It is possible to install everything required on your local system, or to use the pre-configured development docker images.

Create a new Wagon? Check out [Wagon erstellen](04_wagons.md#wagon-erstellen)

⚡ Please note sqlite is no longer supported for development.

#### Docker

Please follow the instructions at [Development](https://github.com/hitobito/development/) for the recommended 🚢 docker development setup.

#### Local installation

##### Setup your system

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

##### Install Dependencies

Install all ruby and node dependencies (in the core folder):

    bundle install
    yarn install

##### Setup Database

In the core directory (`rails db:schema:load` might be currently broken):

    rails db:migrate
    rails wagon:migrate
    rails db:seed
    rails wagon:seed

### Server

In the core directory, in two separate shells:

    rails s
    bin/webpack-dev-server

Login on http://localhost:3000 with the root email (see `wagon/config/settings.yml`) and the password set in `HITOBITO_DEV_PASSWORD`.

### Tests

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

    RAILS_ENABLE_TEST_LOG=1 bin/rspec spec/controllers/addresses_controller_spec.rb

### Background Jobs

To run the Delayed Job background jobs:

    rake jobs:work

🚢 When developing with docker, a job worker is already started. Check it's logs with `docker-compose logs worker`.

### Request Profiling

For profiling single requests, you can add the param `?profile_request=true` to the URL. Output will be written to `tmp/performance`.

### Mailcatcher

Mailcatcher is run as a docker container and can be accessesed on [http://localhost:1080](http://localhost:1080)

### Specific Rake Tasks

Run the following rake tasks inside rails, rails-test container:

| Task                      | Beschreibung                                                                                           |
| ------------------------- | ------------------------------------------------------------------------------------------------------ |
| `rake hitobito:abilities` | Alle Abilities ausgeben.                                                                               |
| `rake hitobito:roles`     | All Gruppen, Rollen und Permissions ausgeben.                                                          |
| `rake annotate`           | Spalten Informationen als Kommentar zu ActiveRecord Modellen hinzufügen.                               |
| `rake rubocop`            | Führt die Rubocop Must Checks (`rubocop-must.yml`) aus und schlägt fehl, falls welche gefunden werden. |
| `rake rubocop:report`     | Führt die Rubocop Standard Checks (`.rubocop.yml`) aus und generiert einen Report für Jenkins.         |
| `rake brakeman`           | Führt `brakeman` aus.                                                                                  |
| `rake mysql`              | Lädt die MySql Test Datenbank Konfiguration für die folgednen Tasks.                                   |
| `rake license:insert`     | Fügt die Lizenz in alle Dateien ein.                                                                   |
| `rake license:remove`     | Entfernt die Lizenz aus allen Dateien.                                                                 |
| `rake license:update`     | Aktualisiert die Lizenz in allen Dateien oder fügt sie neu ein.                                        |
| `rake ci`                 | Führt die Tasks für einen Commit Build aus.                                                            |
| `rake ci:nightly`         | Führt die Tasks für einen Nightly Build aus.                                                           |
| `rake ci:wagon`           | Führt die Tasks für die Wagon Commit Builds aus.                                                       |
| `rake ci:wagon:nightly`   | Führt die Tasks für die Wagon Nightly Builds aus.                                                      |
