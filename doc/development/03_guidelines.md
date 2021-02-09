## Entwicklungs Guidelines

### Code Conventions

Die Code Conventions werden mit Rubocop überprüft und sind in `.rubocop.yml` definiert.
Grundsätzlich folgen wir den Ruby on Rails Standardkonventionen.

Vor jedem Commit soll Rubocop auf die geänderten Dateien losgelassen werden. Die gefundenen
Violations sind unmittelbar zu korrigieren.

    rubocop [files]

Das selbe gilt für Warnungen, welche im Jenkins auftreten (Brakeman, ...).


### Spezifische Guidelines

Allgemeine Konventionen und Erklärungen für spezifische Bereiche.

* Für jeden Link in den View mit `can?` prüfen, ob die Action auch erlaubt ist.
* Permissions definieren grobe Bereiche, Constraints die Bedingungen für konkrete Aktionen. Eine
Aktion entspricht in der Regel einer Controller Action und wird durch ein spezifisches Verb
repräsentiert. Constraints sollen wenn möglich auf den bestehenden Permissions aufbauen und nur in
Ausnahmen auf konkreten Rollen. Neue Permissions dürfen nur äusserts zurückhaltend und sehr gut
begründet eingeführt werden.
* Beim Überprüfen von Berechtigungen mit `can?` immer eine Action (bzw. das Symbol, welches die
Aktion widerspiegelt) entspreched der jeweiligen Aktion verwenden. Negativbeispiel: Die Anzeige
gewisser Attribute mit `can?(:update, entry)` überprüfen. Besser spezifisches Symbol einführen,
falls noch nicht vorhanden, z.B. `can?(:show_sensitive_data, entry)`. Natürlich dürfen die gleichen
Constraints wieder verwendet werden.
* Abilities basieren immer auf einer Instanz (`subject`). Falls eine Action nicht auf einer Instanz
agiert, sind `class_side` abilities zu definieren.
* Controller Specs rendern NIE eine View. Dafür sind die Regression Specs da.
* Commits immer mit dem Redmine/Github Ticket versehen (fixes/refs #123).

#### Durchklicken!

So gut die verschiedenen Tests sein mögen, gewisse Dinge im Browser werden nie abgedeckt sein. Dazu
gehören:

* Wenn das Speichern fehlschlägt und wieder das Formular gerendert wird: Existiert die URL für GET
Requests, damit die Sprachwechsellinks auch in diesem Fall funktionieren?
* Berechtigungen für Links: Werde dieselben Actions geprüft wie in der entsprechenden Controller
Action?
* Wurden die gleichen HTML Markup Elemente verwendet wie auf einer vergleichbaren Seite?
* Ist der Sheet Aufbau konsistent? Ist der Sheet Titel für alle Tabs der selbe?
* Sind in jedem Fall die richtigen Menu Items als aktiv markiert?
* Sind in allen Texten Gendergerechte Bezeichnungen, falls nötig in der Form "/-in" verwendet?

#### Stylesheets in allen Wagons überprüfen

Wenn an den Core Stylesheets Anpassungen vorgenommen werden, müssen diese bei allen Wagons,
insbesondere denjenigen mit customized Styles (z.B. Jubla) überprüft werden, damit die auch dort
funktionieren.


### Checkliste für neue Attribute

Folgende Punkte sind zu berücksichtigen, wenn neue Attribute zu Hitobito Modellen hinzugefügt
werden. Da hitobito über diverse Schnittstellen verfügt, gehen beim Definieren von Attributen rasch
bestimmte Anforderungen vergessen.

* Anzeige, wo?
* Berechtigung Anzeige?
* Bearbeiten, spezielle Input Fields?
* Berechtigung Bearbeiten?
* CSV Export?
* JSON API Index
* JSON API Show
* Sphinx Index

Grundsätzlich bestehen für die Sichtbarkeit der Attribute in Anzeige im GUI, in den CSV Exports
sowie im JSON API die selben Regeln. Ist also z.B. ein Attribut öffentlich, wird es im Adress-CSV
und in der JSON Personen Liste angezeigt, wenn nicht, nur im Full CSV und im Einzelperson JSON,
falls die Berechtigung dafür vorhanden ist.

Ein beispielhafte Anleitung, wie in einem Wagon Attribute hinzugefügt werden können, findest du im Kapitel [Wagons](04_wagons.md#attribute-hinzuf-gen).

#### Personenattribute

* CSV Import
* CSV Export (Adressexport? Voller Export?)
* Log (Papertrail)

#### Rollen umbennen / entfernen

* Migration aller betroffenen `Role` Instanzen (`with_deleted`!).
* Migration aller betroffenen `RelatedRoleType` Instanzen.
* Migration aller Papertrail Versionen (`#object` und `#object_changes`).


### Mehrsprachigkeit / I18n

Die Übersetzung in andere Sprachen erfolgt über die
[Transifex Platform](https://www.transifex.com/organization/hitobito). Dort sind unter der
Organisation hitobito der Core und die verschiedenen Wagon Projekte eingerichtet. Übersetzer
erhalten in der Regel Zugriff auf den Core und die für sie relevanten Wagons.

Folgende Punkte müssen beim Erstellen eines Wagons beachtet werden:

* Ein Transifex Projekt wird nur benötigt, wenn der Wagon übersetzt werden soll. Bleibt er
einsprachig, wird Transifex nicht gebraucht.
* Transifex Projekt Name muss gleich wie der Gem Name des Wagons sein.
* Die Ursprungssprache ist Deutsch (diese kann über Transifex nicht bearbeitet werden)
* Damit Ein-/Mehrzahlformen in allen Sprachen angegeben werden können, müssen in den deutschen
Localefiles immer die Keys `one` und `other` angegeben werden, auch wenn diese (im Deutschen)
identisch sind.
* Für alle im Wagon definierten Sprachen müssen initial entsprechende Locale Dateien erzeugt werden
oder mit `tx pull -l [lang]` von Transifex gepullt werden. Sonst werden nur Sprachen, welche lokal
bereits vorhanden sind gepullt.

Für die verschiedenen Commands für den [Transifex Client](http://docs.transifex.com/client/) wurden
Rake Tasks erstellt. Alle Tasks können in den Wagon Verzeichnissen mit dem Prefix `app:` ausgeführt
werden. Der Client muss dazu installiert sein.

**`hitobito_wagon$ rake app:tx:init`** Erstellt die Transifex Grundkonfiguration für einen Wagon.

**`hitobito_wagon$ rake app:tx:config`** Erstellt Dateikonfigurationen für alle deutschen Locale
Dateien. Muss beim Erstellen einer neuen Locale Datei ausgeführt werden.

**`hitobito_wagon$ rake app:tx:push`** Kopiert die deutschen Locale Dateien auf den Transifex
Server.

**`hitobito_wagon$ rake app:tx:pull`** Kopiert alle übersetzten Dateien vom Transifex Server. Dies
kann ebenfalls von den Entwicklern getan werden, damit die Übersetzungen auch ab und zu im Git
abgelegt werden.


Beim Übersetzen in Transifex sind folgende Punkte zu beachten:

* Die Texte enthalten teilweise Platzhalter, welche mit Prozentzeichen und geschweiften Klammern
eingefügt werden: `%{placeholder}`. Diese Platzhalter sind in der Regel englische Wörter und dürfen
NICHT übersetzt werden, müssen also genau so in die anderen Sprachen übernommen werden. Ansonsten
treten in der laufenden Applikation Fehler auf.
* Gewisse Texte enthalten HTML Tags in eckigen Klammern: `<b>`. Diese dienen oft zur Formattierung
der Texte und sollten bei den entsprechenden Teilen ebenfalls genau so übernommen werden. Auf jedes
öffnende Tag (`<b>`) muss zwingend ein entsprechendes schliessendes Tag mit Schrägstrich folgen
(`</b>`).


### Lizenzen

Hitobito ist ein Open Source Projekt. Entsprechen müssen in jedem (!) File Header
Lizenzinformationen eingefügt werden. Dies kann manuell geschehen oder über den folgenden Rake Task:

    rake license:insert

Der Hauplizenztext und weitere Konfiguration sind im Hitobito Core unter `lib/tasks/license.rake`.
Die einzelnen Wagons können die Konfiguration (Projekt Name, Lizenzinhaber=Kunde, Source Link) für
ihre Files anpassen. Siehe `hitobito_generic/lib/tasks/license.rake`.

### Changelogs führen

Changelogs werden in den Wagons und im Core geführt. Die Dateien dafür, müssen immer CHANGELOG.md genannt werden. Eine neue Version kann folgendermassen spezifiziert werden:

    ## Version 1.0

Wenn du nicht weisst, in welche Versionsnummer deine Contribution aufgenommen wird, dann erstellen einen Titel `## Version 1.X` (falls nicht schon vorhanden).

Um einen Change hinzuzufügen, kann man unter der Version eine Linie wie gefolgt eintragen.

**Es ist wichtig, dass man pro Change nur eine Linie verwendet!**

    ## Version 1.0

    * Mehrsprachigkeit.
    * Schnelleres Laden der Seiten dank Turbolinks.

**Alle Zeilen die nicht einer Version oder einem Change entsprechen werden ignoriert!**
