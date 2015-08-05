## Konzepte

### Fachliche Strukturen

Diese Sicht zeigt die Hauptmodelle in hitobito. Ein vollständiges und aktuelles Datenmodell kann mit dem Befehl `rake erd` generiert werden.

![Fachliches Modell](diagrams/fachmodell.svg)

**Group**: Modelliert die Baumstruktur der Gruppen eines Verbandes. Die konkreten Gruppentypen werden als Subklassen von den jeweiligen Verbandsplugins definiert und mittels [Single Table Inheritance](http://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html) persistiert. Verschiedene Klassenattribute können zur Spezifizierung eines Gruppentyps herangezogen werden, wie beispielsweise die jeweils erlaubten Rollentypen. Die Baumstruktur ist als [Nested Set](http://de.wikipedia.org/wiki/Nested_Sets) persistiert. Es wird unterschieden zwischen einfachen Gruppen und Ebenen/Layer. Ebenen bilden jeweils einen Berechtigungsbereich.

**Person**: Eine Person kann mehrere Rollen in mehreren Gruppen haben (via `Role`), an verschiedenen Events teilnehmen (via `Event::Participation`) und bei mehreren `MailingLists` angemeldet sein (via `Subscription`). Jede Person kann ein Login haben, die Rollen bestimmen ihre Berechtigungen. Änderungen an personenspezifischen Daten werden mit [Paper Trail](https://github.com/airblade/paper_trail) aufgezeichnet. Personen können sowohl natürliche wie auch juristische (Firmen) sein.

**Event**: Ein einfacher Anlass, ein Kurs oder beliebiger weiterer verbandspezifischer Event. Dieser kann von mehreren Gruppen durchgeführt werden. Die Eventtypen werden wie die Gruppen über Klassenattribute spezifiziert und mittels [Single Table Inheritance](http://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html) persistiert. Kurse verfügen darüber hinaus noch über eine Kursart und damit über Qualifikationseigenschaften.

**MailingList**: Jede Gruppe kann beliebig viele Abos haben, welche optional eine E-Mail Adresse haben und dadurch ebenfalls als E-Mail Liste verwendet werden können. Einzelne Personen, jedoch auch bestimmte Rollen einer Gruppe oder Teilnehmende eines Events können Abonnenten sein.


### Wagons

Die Applikation ist aufgeteilt in Core (generischer Teil) und Wagons (Verbandsspezifische Erweiterungen). Zur Funktionsweise von Wagons allgemein siehe auch [wagons](http://github.com/codez/wagons). Falls die Applikation für weitere Verbände customized werden soll, können einfach weitere Wagons erstellt werden.

In einem Wagon können Tabellen um weitere Attribute ergänzt werden, Funktionalitäten, Berechtigungen und Darstellungen angepasst und hinzugefügt werden.


### Gruppen- und Rollentypen

Hitobito verfügt über ein mächtiges Metamodell um Gruppenstrukturen zu beschreiben. Gruppen sind immer von einem spezifischen Typ und in einem Baum angeordnet. Jeder Gruppentyp kann verschiedene Rollentypen definieren.

Der Core von hitobito beinhaltet keine konkreten Gruppen- oder Rollentypen. Diese müssen in separaten Wagons definiert werden, entsprechend der spezifischen Verbandsstruktur. Ein Beispiel für einen Gruppentyp könnte wie folgt aussehen:

    class Group::Layer < Group
      self.layer = true

      children Group::Layer, Group::Board, Group::Basic

      class Leader < Role
        self.permissions = [:layer_full, :contact_data]
      end

      class Member < Role
        self.permissions = [:group_read]
      end

      roles Leader, Member
    end

Ein Gruppentyp erbt immer von der Klasse `Group`. Er kann eine Ebene sein (`self.layer = true`), welche mehrere Gruppen zu einem gemeinsamen Berechtigungsbereich zusammenfasst. Alle Untergruppen einer Ebene gehören zu diesem Bereich, ausser sie sind selbst wieder Ebenen.

Danach sind alle möglichen Untergruppentypen des Gruppentyps definiert (`children Group::Layer, Group::Board, Group::Basic`). Wenn Untergruppen erstellt werden, sind nur diese Typen erlaubt. Wie im Beispiel gezeigt, können Gruppentypen rekursiv organisiert sein.

Die Rollentype können direkt in einem Gruppentyp definiert werden und erben von der Klasse `Role`. Jeder Rollentyp hat eine Liste von Grundberechtigungen (`self.permissions = [:layer_full, :contact_data]`). Diese sind allgemeine Angaben für ein Was und Wo, auf welchen die konkreten Berechtigungen aufbauen. Alle spezifischen Möglichkeiten eines Benutzenden sind von den Rollenberechtigungen abgeleitet, welche sie oder er in den verschiedenen Gruppen hat.


### Berechtigungen

Folgende Grundberechtigungen / Permissions existieren momentan:

**admin**: Administration von applikationsweiten Einstellungen wie Kursarten oder Etikettenformate.

**layer_and_below_full**: Alles Lesen und Schreiben auf dieser Ebene und allen darunter liegenden Ebenen. Erstellen von Anlässen und Abos (Mailinglisten) auf dieser Ebene.

**layer_and_below_read**: Alles Lesen auf dieser Ebene und allen darunter liegenden Ebenen.

**layer_full**: Alles Lesen und Schreiben auf dieser Ebene. Erstellen von Anlässen und Abos (Mailinglisten) auf dieser Ebene.

**layer_read**: Alles Lesen auf dieser Ebene.

**group_full**: Lesen und Schreiben nur auf dieser Gruppe. Erstellen von Anlässen und Abos (Mailinglisten) auf der Gruppe.

**group_read**: Lesen nur auf dieser Gruppe.

**contact_data**: Lesen der Kontaktdaten aller anderen Personen mit Kontaktdatenberechtigung.

**approve_applications**: Bestätigen der Kursanmeldungen für Personen dieser Ebene.


Folgende zwei Rake Tasks helfen bei der Dokumentation der Rollen und Berechtigungen:

    rake hitobito:roles

Gibt alle Gruppen und zugehörigen Rollen und deren Grundberechtigungen aus. Strukturierung nach Ebene, Gruppen, Rollen und Permissions. Globale Gruppen können bei jeder Gruppe als Untergruppe erstellt werden, Globale Rollen (Global Global) sind bei allen Gruppen verfügbar.

    rake hitobito:abilities

Gibt alle Berechtigungen entsprechend den Permissions aus. Übersicht über die Definition der Berechtigungen, welche ein Benutzer benötigt, um eine bestimmte Aktion auf einem bestimmten Modell auszuführen.

Die Constraint gibt an, welche weiteren Bedinungen erfüllt sein müssen, z.B. `in_same_group` bedeutet, dass das Model in der selben Gruppe wie die zugehörige Permission sein muss. Die Permission `any` trifft auf alle Benutzer unabhängig ihrer Permissions zu, die Permission `general` wird _zusätzlich_ zu allen anderen Constraints dieser Aktion ebenfalls geprüft. Mindestens eine Constraint muss erfüllt sein, damit ein Benutzer die entsprechende Aktion ausführen kann.

Lesebeispiel am Beispiel Jubla: _Kann ein Mitglied der Bundesleitung einen Anlass einer Schar bearbeiten?_

* Ein Mitglied der Bundesleitung hat die Permissions `[:admin, :layer_and_below_full, :contact_data]`.
* Bearbeiten (`update`) eines Events erfordert `any/for_leaded_events`, `group_full/in_same_group`, `layer_and_below_full/in_same_layer_or_below` sowie die allgemeine Constraint `at_least_one_group_not_deleted_and_not_closed_or_admin`.
* Der Anlass einer Schar ist unterhalb der Ebene Bund des Bulei Mitglieds, somit kommt `layer_and_below_full/in_same_layer_or_below` zum Zug.
* Die allgemeine Constraint wirkt in jedem Fall. Falls die Schar also nicht gelöscht ist (`at_least_one_group_not_deleted_and_not_closed_or_admin`), kann dieser Benutzer den Anlass bearbeiten. (Das `not_closed_..` trifft nur auf Kurse zu).


### Single Table Inheritance

TODO: used_attributes


### Mailing Listen / Abos

Hitobito stellt eine simple Implementation von Mailing Listen zur Verfügung. Diese können in der Applikation beliebig erstellt und verwaltet werden. Dies geschieht in den Modellen `MailingList` und `Subscription`.

Alle E-Mails an die Applikationsdomain (z.B `news@db.jubla.ch`) werden über einen Catch-All Mail Account gesammelt. Dabei muss der Mailserver den zusätzlichen E-Mail Header `X-Envelope-To` setzen, welcher den ursprünglichen Empfänger enthält (z.B. `news`). Von der Applikation wird dieser Account in einem Background Job über POP3 regelmässig gepollt. Die eingetroffenen E-Mails werden danach wie folgt verarbeitet:

1. Verwerfe das Email, falls der Empfänger keine definierte Mailing Liste ist.
1. Sende eine Rückweisungsemail, falls der Absender nicht berechtigt ist.
1. Leite das Email weiter an alle Empfänger der Mailing Liste.

#### No-Reply Liste

Damit jemand bei ungültigen E-Mailadressen oder sonstigen Versandfehlern von E-Mails benachrichtigt wird, sollte eine spezielle Mailingliste (in der Applikation unter "Abos" > "Abo erstellen") eingerichtet werden, welche auf die Applikations-Sendeadresse lautet (`Settings.email.sender`, z.B. `noreply@db.jubla.ch`). Als zusätzlicher Absender muss dabei der verwendete Mailer Daemon definiert werden (z.B. `MAILER-DAEMON@puzzle.ch`) Bei dieser Liste sollte eine Person der Organisation als Abonnent vorhanden sein, welcher sich um die fehlerhaften Adressen kümmert.


