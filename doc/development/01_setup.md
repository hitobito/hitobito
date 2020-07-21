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

For executing Wagon specific tests: (from core)

    spring rails wagon:test

Um einzelne Tests auszuführen, muss die Testdatenbank vorbereitet sein. Dazu muss nach dem Wechsel
von Core in einen Wagon (und umgekehrt) folgender Befehl ausgeführt werden:

    spring rails db:test:prepare

Danach können spezifische Tests auch mit Spring und direkt über Rspec ausgeführt werden, z.B.:

    spring rspec spec/domain/import


### Request Profiling

Um einen einzelnen Request zu Profilen, kann der Parameter `?profile_request=true` in der URL
angehängt werden. Der Output wird nach `tmp/performance` geschrieben.


### Delayed Job

Um die Background Jobs abzuarbeiten (z.B. um Mails zu versenden), muss Delayed Job gestartet werden:

    rake jobs:work


### Mailcatcher

Das development Environment ist so konfiguriert, dass alle E-Mails per SMTP an `localhost:1025`
geschickt werden. Am einfachsten kann man diese E-Mails lesen, indem man mailcatcher startet:

    mailcatcher -v

und dann mittles Browser auf `http://localhost:1080` E-Mails liest.


### Spezifische Rake Tasks

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
