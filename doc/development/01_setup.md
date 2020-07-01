## Development

Basis Setup: [Instructions](https://github.com/hitobito/hitobito#development).

Siehe [Wagon erstellen](04_wagons.md#wagon-erstellen), wenn du frisch startest und einen Wagon für eine neue
Organisation erstellen willst.

### Tests

Als erstes eine console im test container starten:

    docker-compose exec rails-test bash -c 'bundle exec bash'

Ausführen der Tests:

    rails spec

Dies führt aus Performancegründen keine Javascript/Feature Specs aus. Diese können explizit
gestartet werden:

    rails spec:features

Ausführen der Wagon Tests:

    rails wagon:test

Um einzelne Tests auszuführen, muss die Testdatenbank vorbereitet sein:

    rails db:test:prepare

Danach können spezifische Tests auch mit Spring und direkt über Rspec ausgeführt werden, z.B.:

    spring rspec spec/domain/import


### Request Profiling

Um einen einzelnen Request zu Profilen, kann der Parameter `?profile_request=true` in der URL
angehängt werden. Der Output wird nach `tmp/performance` geschrieben.


### Sphinx

Sphinx läuft in einem Container der über docker-compose gestartet wird.

Achtung: Der Index wird grundsätzlich nur über diesen Aufruf aktualisiert! Änderungen an der DB
werden für die Volltextsuche also erst sichtbar, wenn wieder neu indexiert wurde. Auf der Produktion
läuft dazu alle 10 Minuten ein Delayed Job.

### Delayed Job

Um die Background Jobs abzuarbeiten (z.B. um Mails zu versenden), läuft ein Worker in einem eigenen Container. Die Logs können mit folgendem Befehl abgerufen werden:

    docker-compose logs -f worker

### Mailcatcher

Das development Environment ist so konfiguriert, dass alle E-Mails per SMTP an `localhost:1025`
geschickt werden. Mailcatcher wird ebenfalls mit docker-compose gestartet und steht unter `http://localhost:1080` zur Verfügung.

### Spezifische Rake Tasks

Um die Tasks auszuführen kann eine console im Rails Container gestartet werden:

    docker-compose exec rails bash -c 'bundle exec bash'

| Task | Beschreibung |
| --- | --- |
| `rails hitobito:abilities` | Alle Abilities ausgeben. |
| `rails hitobito:roles` | All Gruppen, Rollen und Permissions ausgeben. |
| `rails annotate` | Spalten Informationen als Kommentar zu ActiveRecord Modellen hinzufügen. |
| `rails rubocop` | Führt die Rubocop Must Checks (`rubocop-must.yml`) aus und schlägt fehl, falls welche gefunden werden. |
| `rails rubocop:report` | Führt die Rubocop Standard Checks (`.rubocop.yml`) aus und generiert einen Report für Jenkins. |
| `rails brakeman` | Führt `brakeman` aus. |
| `rails mysql` | Lädt die MySql Test Datenbank Konfiguration für die folgednen Tasks. |
| `rails license:insert` | Fügt die Lizenz in alle Dateien ein. |
| `rails license:remove` | Entfernt die Lizenz aus allen Dateien. |
| `rails license:update` | Aktualisiert die Lizenz in allen Dateien oder fügt sie neu ein. |
| `rails ci` | Führt die Tasks für einen Commit Build aus. |
| `rails ci:nightly` | Führt die Tasks für einen Nightly Build aus. |
| `rails ci:wagon` | Führt die Tasks für die Wagon Commit Builds aus. |
| `rails ci:wagon:nightly` | Führt die Tasks für die Wagon Nightly Builds aus. |
