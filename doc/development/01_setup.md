## Setup der Entwicklungsumgebung

Die Applikation läuft unter Ruby >= 1.9.3, Rails 4 und Sqlite3 (development) / MySQL (production). 
Zur Entwicklung wird RVM verwendet.


### System

Als Entwicklungsdatenbank wird Sqlite3 verwendet. Zur Emulation des Produktionsenvironments muss 
MySQL installiert sein. Die folgenden Befehle gehen von einem Ubuntu Linux als Entwicklungssystem aus. 
Bei einem anderen System müssen die Befehle entsprechend angepasst werden.

    sudo apt-get install sqlite3 mysql-client libmysqlclient-dev mysql-server sphinxsearch memcached 
    imagemagick transifex-client 


### Source

Hitobito Core und die entsprechenden Wagons aus dem Git Remote klonen und das Wagonfile kopieren. 
Der Core und die Wagons müssen nebeneinander im gleichen Hauptverzeichnis sein.

    git clone https://github.com/hitobito/hitobito.git

    git clone https://github.com/hitobito/hitobito_[wagon].git

    cp hitobito/Wagonfile.ci hitobito/Wagonfile

    cp hitobito/Gemfile.lock hitobito_[wagon]/


### Setup

Dependencies installieren (im Hitobito Core):

    bundle

Datenbank erstellen

    rake db:create

Initialisieren der Datenbank, laden der Seeds und Wagons:

    rake db:setup:all

Starten des Entwicklungsservers:

    rails server


### Tests

Ausführen der Tests:

    rake

Dies führt aus Performancegründen keine Javascript/Feature Specs aus. Diese können explizit 
gestartet werden:

    rake spec:features

Ausführen der Wagon Tests (vom Hitobito Core aus):

    rake wagon:test

Um einzelne Tests auszuführen, muss die Testdatenbank vorbereitet sein. Dazu muss nach dem Wechsel 
von Core in einen Wagon (und umgekehrt) folgender Befehl ausgeführt werden:

    rake db:test:prepare

Danach können spezifische Tests auch mit Spring und direkt über Rspec ausgeführt werden, z.B.:

    spring rspec spec/domain/import


### Request Profiling

Um einen einzelnen Request zu Profilen, kann der Parameter `?profile_request=true` in der URL 
angehängt werden. Der Output wird nach `tmp/performance` geschrieben.


### Datenbank Auswahl

Im Entwicklungsmodus wird per Default mit Sqlite3 gearbeitet. Um Tests mit MySQL auszuführen, kann 
der folgende Befehl verwendet werden. Dabei wird immer die Testdatenbank (hitobito_test) verwendet.

    rake mysql test

Um den Server / Konsole mit MySQL zu starten, existiert das folgende Script:

     bin/with_mysql rails xxx

Dieses Skript kann auch benutzt werden, um Rake Tasks auf der Development Datenbank laufen zu 
lassen.


### Sphinx

Um die Volltextsuche zu verwenden, muss der Index erstellt
 
    script/with_mysql rake ts:index
 
und Sphinx gestartet werden: 

    rake ts:start

Achtung: Der Index wird grundsätzlich nur über diesen Aufruf aktualisiert! Änderungen an der DB 
werden für die Volltextsuche also erst sichtbar, wenn wieder neu indexiert wurde. Auf der Produktion 
läuft dazu alle 10 Minuten ein Delayed Job.

Sphinx läuft nur unter MySql. Wenn Sphinx bei der Entwicklung verwendet werden soll, muss der Rails 
Server wie oben erwähnt mit MySql gestart werden.


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


