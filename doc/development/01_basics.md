## Development

### Setup

Please follow the instructions at [Development](https://github.com/hitobito/development/)

Create a new Wagon? Check out [Wagon erstellen](04_wagons.md#wagon-erstellen)

⚡ Please note sqlite is no longer supported for development.

### Tests

For executing any of the following commands, start a console inside rails-test container:

    docker-compose exec rails-test bash

Execute all tests:

    spring rails spec

For performance reasons, this does not include any Javascript/Feature Specs. To run those tests: 

    spring rails spec:features

For executing Wagon specific tests:

    cd ../hitobito_generic # change to desired wagon
    rails spec

Switching between core and wagon database for executing single tests:

    spring rails db:test:prepare

Executing a specific test:

    spring rspec spec/domain/import_spec.rb
    
For executing a single feature spec call:

    spring rspec --tag type:feature spec/features/role_lists_controller_spec.rb

### Request Profiling

For profiling single requests, you can add the param `?profile_request=true` to the URL. Output will be written to `tmp/performance`.

### Delayed Job

Starting up development containers includes one with the delayed job worker. To check it's logs:

    docker-compose logs worker
    
### Mailcatcher

Access mailcatcher with your favourite browser [http://localhost:1080](http://localhost:1080)

### Specific Rake Tasks

Run the following rake tasks inside rails, rails-test container:

| Task | Beschreibung |
| --- | --- |
| `rake hitobito:abilities` | Alle Abilities ausgeben. |
| `rake hitobito:roles` | All Gruppen, Rollen und Permissions ausgeben. |
| `rake annotate` | Spalten Informationen als Kommentar zu ActiveRecord Modellen hinzufügen. |
| `rake rubocop` | Führt die Rubocop Must Checks (`rubocop-must.yml`) aus und schlägt fehl, falls welche gefunden werden. |
| `rake rubocop:report` | Führt die Rubocop Standard Checks (`.rubocop.yml`) aus und generiert einen Report für Jenkins. |
| `rake brakeman` | Führt `brakeman` aus. |
| `rake mysql` | Lädt die MySql Test Datenbank Konfiguration für die folgednen Tasks. |
| `rake license:insert` | Fügt die Lizenz in alle Dateien ein. |
| `rake license:remove` | Entfernt die Lizenz aus allen Dateien. |
| `rake license:update` | Aktualisiert die Lizenz in allen Dateien oder fügt sie neu ein. |
| `rake ci` | Führt die Tasks für einen Commit Build aus. |
| `rake ci:nightly` | Führt die Tasks für einen Nightly Build aus. |
| `rake ci:wagon` | Führt die Tasks für die Wagon Commit Builds aus. |
| `rake ci:wagon:nightly` | Führt die Tasks für die Wagon Nightly Builds aus. |
