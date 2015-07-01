## Konzepte

### Fachliche Strukturen

Diese Sicht zeigt die Hauptmodelle in hitobito. Ein vollständiges und aktuelles Datenmodell kann mit dem Befehl `rake erd` generiert werden.

![Fachliches Modell](diagrams/fachmodell.svg)

**Group**: Modelliert die Baumstruktur der Gruppen eines Verbandes. Die konkreten Gruppentypen werden als Subklassen von den jeweiligen Verbandsplugins definiert und mittels [Single Table Inheritance](http://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html) persistiert. Verschiedene Klassenattribute können zur Spezifizierung eines Gruppentyps herangezogen werden, wie beispielsweise die jeweils erlaubten Rollentypen. Die Baumstruktur ist als [Nested Set](http://de.wikipedia.org/wiki/Nested_Sets) persistiert. Es wird unterschieden zwischen einfachen Gruppen und Ebenen/Layer. Ebenen bilden jeweils einen Berechtigungsbereich.

**Person**: Eine Person kann mehrere Rollen in mehreren Gruppen haben, an verschiedenen Events teilnehmen und bei mehreren MailingLists angemeldet sein. Jede Person kann ein Login haben, die Rollen bestimmen ihre Berechtigungen. Änderungen an personenspezifischen Daten werden mit [Paper Trail](https://github.com/airblade/paper_trail) aufgezeichnet. Personen können sowohl natürliche wie auch juristische (Firmen) sein.

**Event**: Ein einfacher Anlass, ein Kurs oder beliebiger weiterer verbandspezifischer Event. Dieser kann von mehreren Gruppen durchgeführt werden. Die Eventtypen werden wie die Gruppen über Klassenattribute spezifiziert und mittels [Single Table Inheritance](http://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html) persistiert. Kurse verfügen darüber hinaus noch über eine Kursart und damit über Qualifikationseigenschaften.

**MailingList**: Jede Gruppe kann beliebig viele Abos haben, welche optional eine E-Mail Adresse haben und dadurch ebenfalls als E-Mail Liste verwendet werden können. Einzelne Personen, jedoch auch bestimmte Rollen einer Gruppe oder Teilnehmende eines Events können Abonnenten sein.


### Wagons

Die Applikation ist aufgeteilt in Core (generischer Teil) und Wagon (Verbandsspezifische Erweiterungen). Im Development und Production Mode sind jeweils beide Teile geladen, in den Tests nur der Core bzw. in den Wagon Tests der Core und der spezifische Wagon. Dies wird über das Gemfile gesteuert. Zur Funktionsweise von Wagons allgemein siehe auch [wagons](http://github.com/codez/wagons).

Falls die Applikation für weitere Verbände customized werden soll, können einfach weitere Wagons erstellt werden.

Einige grundlegende Dinge, welche in Zusammenhang mit Wagons zu beachten sind:

* Der hitobito Core und alle Wagon Verzeichnisse müssen im gleichen Haupverzeichnis sein.
* Zu Entwicklung kann die Datei `Wagonfile.ci` nach `Wagonfile` kopiert werden, um alle Wagons in benachbarten Verzeichnissen zu laden. Falls nur bestimmte Wagons aktiviert werden sollen, kann dies ebenfalls im `Wagonfile` konfiguriert werden.
* Wagons verwenden die gleiche Datenbank wie der Core. Wenn im Core Migrationen erstellt werden, müssen alle Wagon Migrationen daraus entfernt werden, bevor das `schema.rb` generiert werden kann. Dies geht am einfachsten, indem die development Datenbank komplett gelöscht und wiederhergestellt wird.
* Wenn neue Gems zum Core hinzugefügt werden, müssen alle `Gemfile.lock` Dateien in den Wagons aktualisert werden. Dies geschieht am einfachsten mit `rake wagon:bundle:update`.
* Ein neuer Wagon kann mit `rails g wagon [name]` erstellt werden. Danach sollte dieser von `vendor/wagons` in ein benachbartes Verzeichnis des Cores verschoben werden und die Datei `app_root.rb` des Wagons entsprechend angepasst werden.
