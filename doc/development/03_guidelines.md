## Entwicklungs Guidelines

### Conventions

### Checkliste für neue Attribute

### Wagons

Die Applikation ist aufgeteilt in Core (generischer Teil) und Wagon (Verbandsspezifische Erweiterungen). Im Development und Production Mode sind jeweils beide Teile geladen, in den Tests nur der Core bzw. in den Wagon Tests der Core und der spezifische Wagon. Dies wird über das Gemfile gesteuert. Zur Funktionsweise von Wagons allgemein siehe auch [wagons](http://github.com/codez/wagons).

Einige grundlegende Dinge, welche in Zusammenhang mit Wagons zu beachten sind:

* Der hitobito Core und alle Wagon Verzeichnisse müssen im gleichen Haupverzeichnis sein.
* Zu Entwicklung kann die Datei `Wagonfile.ci` nach `Wagonfile` kopiert werden, um alle Wagons in benachbarten Verzeichnissen zu laden. Falls nur bestimmte Wagons aktiviert werden sollen, kann dies ebenfalls im `Wagonfile` konfiguriert werden.
* Wagons verwenden die gleiche Datenbank wie der Core. Wenn im Core Migrationen erstellt werden, müssen alle Wagon Migrationen daraus entfernt werden, bevor das `schema.rb` generiert werden kann. Dies geht am einfachsten, indem die development Datenbank komplett gelöscht und wiederhergestellt wird.
* Wenn neue Gems zum Core hinzugefügt werden, müssen alle `Gemfile.lock` Dateien in den Wagons aktualisert werden. Dies geschieht am einfachsten mit `rake wagon:bundle:update`.
* Ein neuer Wagon kann mit `rails g wagon [name]` erstellt werden. Danach sollte dieser von `vendor/wagons` in ein benachbartes Verzeichnis des Cores verschoben werden und die Datei `app_root.rb` des Wagons entsprechend angepasst werden.

### Mehrsprachigkeit / I18n

Die Übersetzung in andere Sprachen erfolgt über die [Transifex Platform](https://www.transifex.com/organization/hitobito). Dort sind unter der Organisation hitobito der Core und die verschiedenen Wagon Projekte eingerichtet. Übersetzer erhalten in der Regel Zugriff auf den Core und die für sie relevanten Wagons.

Folgende Punkte müssen beim Erstellen eines Wagons beachtet werden:

* Ein Transifex Projekt wird nur benötigt, wenn der Wagon übersetzt werden soll. Bleibt er einsprachig, wird Transifex nicht gebraucht.
* Transifex Projekt Name muss gleich wie der Gem Name des Wagons sein.
* Die Ursprungssprache ist Deutsch (diese kann über Transifex nicht bearbeitet werden)
* Damit Ein-/Mehrzahlformen in allen Sprachen angegeben werden können, müssen in den deutschen Localefiles immer die Keys `one` und `other` angegeben werden, auch wenn diese (im Deutschen) identisch sind.
* Für alle im Wagon definierten Sprachen müssen initial entsprechende Locale Dateien erzeugt werden oder mit `tx pull -l [lang]` von Transifex gepullt werden. Sonst werden nur Sprachen, welche lokal bereits vorhanden sind gepullt.

Für die verschiedenen Commands für den [Transifex Client](http://docs.transifex.com/client/) wurden Rake Tasks erstellt. Alle Tasks können in den Wagon Verzeichnissen mit dem Prefix `app:` ausgeführt werden. Der Client muss dazu installiert sein.

**`hitobito_wagon$ rake app:tx:init`** Erstellt die Transifex Grundkonfiguration für einen Wagon.

**`hitobito_wagon$ rake app:tx:config`** Erstellt Dateikonfigurationen für alle deutschen Locale Dateien. Muss beim Erstellen einer neuen Locale Datei ausgeführt werden.

**`hitobito_wagon$ rake app:tx:push`** Kopiert die deutschen Locale Dateien auf den Transifex Server.

**`hitobito_wagon$ rake app:tx:pull`** Kopiert alle übersetzten Dateien vom Transifex Server. Dies kann ebenfalls von den Entwicklern getan werden, damit die Übersetzungen auch ab und zu im Git abgelegt werden.


Beim Übersetzen in Transifex sind folgende Punkte zu beachten:

* Die Texte enthalten teilweise Platzhalter, welche mit Prozentzeichen und geschweiften Klammern eingefügt werden: `%{placeholder}`. Diese Platzhalter sind in der Regel englische Wörter und dürfen NICHT übersetzt werden, müssen also genau so in die anderen Sprachen übernommen werden. Ansonsten treten in der laufenden Applikation Fehler auf.
* Gewisse Texte enthalten HTML Tags in eckigen Klammern: `<b>`. Diese dienen oft zur Formattierung der Texte und sollten bei den entsprechenden Teilen ebenfalls genau so übernommen werden. Auf jedes öffnende Tag (`<b>`) muss zwingend ein entsprechendes schliessendes Tag mit Schrägstrich folgen (`</b>`).

