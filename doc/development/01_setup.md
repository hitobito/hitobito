## Setup der Entwicklungsumgebung

Die Applikation läuft unter Ruby >= 1.9.3, Rails 4 und Sqlite3 (development) / MySQL (production). 


### System

Grundsätzlich muss für hitobito eine Ruby Version grösser gleich 1.9.3 sowie Bundler vorhanden sein.
Siehe dazu https://www.ruby-lang.org/en/documentation/installation/.

Als Entwicklungsdatenbank wird Sqlite3 verwendet. Zur Emulation des Produktionsenvironments muss 
MySQL installiert sein. Die Befehle gehen von einem Ubuntu Linux als Entwicklungssystem aus. 
Bei einem anderen System müssen die Befehle entsprechend angepasst werden.

    sudo apt-get install sqlite3 libsqlite3-dev libgmp3-dev
    sudo apt-get install mysql-client libmysqlclient-dev mysql-server

Folgende Dritt-Packete sind für die verschiedenen Features von hitobito zusätzlich erforderlich. 

    sudo apt-get install sphinxsearch memcached imagemagick transifex-client graphviz


### Source

Hitobito Core und die entsprechenden Wagons aus dem Git Remote klonen und das Wagonfile kopieren. 
Der Core und die Wagons müssen nebeneinander im gleichen Hauptverzeichnis sein. 
Dazu muss Git installiert sein.

    sudo apt-get install git
    
    cd your-code-directory

    git clone https://github.com/hitobito/hitobito.git

    git clone https://github.com/hitobito/hitobito_[wagon].git

    cp hitobito/Wagonfile.ci hitobito/Wagonfile

    cp hitobito/Gemfile.lock hitobito_[wagon]/
    
Siehe [Wagon erstellen](#wagon-erstellen), wenn du frisch startest und einen Wagon für eine neue 
Organisation erstellen willst.  


### Setup

Ruby Gem Dependencies installieren (alle folgenden Befehle im Hitobito Core Verzeichnis ausführen):

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
gestartet werden. Dazu muss xvfb installiert sein.

    sudo apt-get install xvfb
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

Im Entwicklungsmodus wird per Default mit Sqlite3 gearbeitet. 

Um den Server, die Konsole oder Rake Tasks im Development Environment mit MySQL zu starten, 
existiert das folgende Script:

     bin/with_mysql rails xxx

Wenn auf der DB ein Passwort verwendet wird, kann es folgendermassen angegeben weden:
   
     RAILS_DB_PASSWORD=password bin/with_mysql rails xxx

Um Tests mit MySQL auszuführen, kann der folgende Befehl verwendet werden. Dabei wird immer die 
Testdatenbank (hitobito_test) verwendet.

    rake mysql test


### Sphinx

Sphinx läuft nur unter MySql. Wenn MySql/Sphinx bei der Entwicklung verwendet werden soll, müssen 
die Datenbank Tasks und der Rails Server wie oben erwähnt mit `bin/with_mysql` gestart werden.

Um die Volltextsuche zu verwenden, muss erst der Index erstellt
 
    bin/with_mysql rake ts:index
 
und dann Sphinx gestartet werden: 

    rake ts:start

Achtung: Der Index wird grundsätzlich nur über diesen Aufruf aktualisiert! Änderungen an der DB 
werden für die Volltextsuche also erst sichtbar, wenn wieder neu indexiert wurde. Auf der Produktion 
läuft dazu alle 10 Minuten ein Delayed Job.


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


### Wagon erstellen

Um für hitobito eine Gruppenstruktur zu defnieren, die Grundfunktionaliäten zu erweitern oder
gewisse Features für mehrere Organisationen gemeinsam verfügbar zu machen, können Wagons verwendet
werden. Siehe dazu auch die Wagon Guidelines. Die Grundstruktur eines neuen Wagons kann sehr 
einfach im Hauptprojekt generiert werden (Die Templates dazu befinden sich in `lib/templates/wagon`):

    rails generate wagon [name]
    
Danach müssen noch folgende spezifischen Anpassungen gemacht werden:

* Dateien von `hitobito/vendor/wagons/[name]` nach `hitobito_[name]` verschieben.
* Eigenes Git Repo für den Wagon erzeugen.
* `Gemfile.lock` vom Core in den Wagon kopieren.
* Organisation im Lizenz Generator (`lib/tasks/license.rake`) anpassen und überall Lizenzen 
  hinzufügen: `rake app:license:insert`.
* Organisation in `COPYING` ergänzen.
* `AUTHORS` ergänzen.
* In `hitobito_[name].gemspec` authors, email, summary und description anpassen.

Falls der Wagon für eine neue Organisation ist, können noch diese Punkte angepasst werden:

* In den Seeddaten Entwickler- und Kundenaccount hinzufügen: `db/seed/development/1_people.rb` unter `devs`.
* Die gewünschte E-Mail des Root Users in `config/settings.yml` eintragen.
* Falls die Applikation mehrsprachig sein soll: Transifex Projekt erstellen und vorbereiten. 
  Siehe dazu auch die Mehrsprachigkeits Guidelines.

Falls der Wagon nicht für eine spezifische Organisation ist und keine Gruppenstruktur definiert,
sollten folgende generierten Dateien gelöscht werden:

* Gruppen Models: `rm -rf app/models/group/root.rb app/models/[name]/group.rb`
* Übersetzungen der Models in `config/locales/models.[name].de.yml`
* Seeddaten: `rm -rf db/seeds`

Damit entsprechende Testdaten für Tests sowie Tarantula vorhanden sind, müssen die Fixtures im Wagon entsprechend der generierten Organisationsstruktur angepasst werden.
* Anpassen der Fixtures für people, groups, roles, events, usw. (`spec/fixtures`)
* Anpassen der Tarantula Tests im Wagon (`test/tarantula/tarantula_test.rb`)

### Gruppenstruktur erstellen

Nachdem für eine Organisation ein neuer Wagon erstellt worden ist, muss oft auch eine 
Gruppenstruktur definiert werden. Wie die entsprechenden Modelle aufgebaut sind, ist in der 
Architekturdokumentation beschrieben. Hier die einzelnen Schritte, welche für das Aufsetzen der
Entwicklungsumgebung noch vorgenommen werden müssen:

* Am Anfang steht die alleroberste Gruppe. Die Klasse in `app/models/group/root.rb` entsprechend 
  umbenennen (z.B. nach "Dachverband") und erste Rollen definieren. 
* `app/models/[name]/group.rb#root_types` entsprechend anpassen.
* In `config/locales/models.[name].de.yml` Übersetzungen für Gruppe und Rollen hinzufügen.
* In `db/seed/development/1_people.rb` die Admin Rolle für die Entwickler anpassen.
* In `db/seed/groups.rb` den Seed der Root Gruppe anpassen.
* In `spec/fixtures/groups.yml` den Typ der Root Gruppe anpassen.
* In `spec/fixtures/roles.yml` die Rollentypen anpassen.
* Tests ausführen
* Weitere Gruppen und Rollen inklusive Übersetzungen definieren.
* In `db/seed/development/0_groups.rb` Seed Daten für die definierten Gruppentypen definieren.
* In `spec/fixtures/groups.yml` Fixtures für die definierten Gruppentypen definieren. Es empfielt
  sich, die selben Gruppen wie in den Development Seeds zu verwenden.
* `README.md` mit Output von `rake app:hitobito:roles` ergänzen.
