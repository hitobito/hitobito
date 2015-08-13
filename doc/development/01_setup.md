## Setup der Entwicklungsumgebung

### System

Als Entwicklungsdatenbank wird Sqlite3 verwendet. Zur Emulation des Produktionsenvironments muss MySQL installiert sein.
Die folgenden Befehle gehen von einem Ubuntu Linux als Entwicklungssystem aus. Bei einem anderen System müssen die Befehle entsprechend angepasst werden.

    sudo apt-get install sqlite3 mysql-client libmysqlclient-dev mysql-server sphinxsearch memcached transifex-client


### Source

Hitobito Core und die entsprechenden Wagons aus dem Git Remote klonen und das Wagonfile kopieren. Der Core und die Wagons müssen nebeneinander im gleichen Hauptverzeichnis sein.

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

Dies führt aus Performancegründen keine Javascript/Feature Specs aus. Diese können explizit gestartet werden:

    rake spec:features

Ausführen der Wagon Tests (vom Hitobito Core aus):

    rake wagon:test

Um einzelne Tests auszuführen, muss die Testdatenbank vorbereitet sein. Dazu muss nach dem Wechsel von Core in einen Wagon (und umgekehrt) folgender Befehl ausgeführt werden:

    RAILS_ENV=test rake db:test:prepare

Danach können spezifische Tests auch mit Spring und direkt über Rspec ausgeführt werden, z.B.:

    spring rspec spec/domain/import
