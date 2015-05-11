## Konzepte

### Fachliche Strukturen

Diese Sicht zeigt die Hauptmodelle in hitobito. Ein vollständiges und aktuelles Datenmodell kann mit dem Befehl `rake erd` generiert werden.

![Fachliches Modell](diagrams/fachmodell.svg)

**Group**: Modelliert die Baumstruktur der Gruppen eines Verbandes. Die konkreten Gruppentypen werden als Subklassen von den jeweiligen Verbandsplugins definiert und mittels [Single Table Inheritance](http://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html) persistiert. Verschiedene Klassenattribute können zur Spezifizierung eines Gruppentyps herangezogen werden, wie beispielsweise die jeweils erlaubten Rollentypen. Die Baumstruktur ist als [Nested Set](http://de.wikipedia.org/wiki/Nested_Sets) persistiert. Es wird unterschieden zwischen einfachen Gruppen und Ebenen/Layer. Ebenen bilden jeweils einen Berechtigungsbereich.

**Person**: Eine Person kann mehrere Rollen in mehreren Gruppen haben, an verschiedenen Events teilnehmen und bei mehreren MailingLists angemeldet sein. Jede Person kann ein Login haben, die Rollen bestimmen ihre Berechtigungen. Änderungen an personenspezifischen Daten werden mit [Paper Trail](https://github.com/airblade/paper_trail) aufgezeichnet. Personen können sowohl natürliche wie auch juristische (Firmen) sein.

**Event**: Ein einfacher Anlass, ein Kurs oder beliebiger weiterer verbandspezifischer Event. Dieser kann von mehreren Gruppen durchgeführt werden. Die Eventtypen werden wie die Gruppen über Klassenattribute spezifiziert und mittels [Single Table Inheritance](http://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html) persistiert. Kurse verfügen darüber hinaus noch über eine Kursart und damit über Qualifikationseigenschaften.

**MailingList**: Jede Gruppe kann beliebig viele Abos haben, welche optional eine E-Mail Adresse haben und dadurch ebenfalls als E-Mail Liste verwendet werden können. Einzelne Personen, jedoch auch bestimmte Rollen einer Gruppe oder Teilnehmende eines Events können Abonnenten sein.
