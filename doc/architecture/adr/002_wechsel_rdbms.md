# ADR-002 Wechsel oder Upgrade des RDBMS

Status: **Vorschlag**

Entscheid: **Wechsel von MySQL zu PostgreSQL**

## Kontext

Während einiger Deployments gab es Probleme mit den Migrationen. Auf der MT-Instanz laufen sie teilweise parallel, was die Analyse erschwert. Um hier eine klare Abgrenzung zu bekommen, wären Transaktionen für strukturelle Änderungen hilfreich. Weiterhin sind in der aktuell verwendete Version von MySQL nicht immer die passenden Datentypen vorhanden, wodurch die DB eher zum "Dumb Datastore" wird und weniger zur Applikation beitragen kann.

## Optionen

### Wechsel zu PostgreSQL

- ➕ Transaktionen umfassen auch strukturelle Anpassungen, Migrationen sind damit self-contained und können atomar angewandet werden.
- ➕ Mehr Datentypen ermöglichen bessere Speicherung von Daten (Boolean, Array-Datentypen)
- ➕ Möglichkeit, FTS ohne Sphinx umzusetzen
- ➖ Applikation muss teilweise angepasst werden
- ➖ Backup muss angepasst werden

## Konsequenzen

Wir können Features von PostgreSQL verwenden:

- Strukturtransaktionen, die im Fehlerfall komplett zurückgerollt werden können
- Alle Datentypen als Array (Anwendungsbeispiel: eine Person in mehreren Familien) und auf DB-Ebene auswerten
- Echte Booleans (Detail, aber schön)
- JSON-Datentypen, Struktur kann auf DB-Ebene ausgewertet werden
- Partial indices (kann zu kleineren und damit schnelleren Indizes führen)
- Volltextsuche (nicht so mächtig wie Sphinx, aber näher an den Daten)

Wir müssen eventuell Wissen über PostgreSQL aufbauen:

- Betrieb (Erfahrung aus anderen Projekten ist vorhanden)
- Leicht anderer SQL-Dialekt, näher am Standard, aber eben anders als MySQL

Wir müssen die Anwendung entweder DB-agnostisch machen oder die MySQL-Anpassungen zu PostgreSQL-Anpassungen umschreiben.

## Kommentare/Advice

### tbu 2022-02-18

Wechsel von MySQL zu PostgreSQL im Dev-Setup. App wurde dadurch DB-agnostisch, der Wechsel zu PostgreSQL steht noch aus.

Strategie war "Sprung ins kalte Wasser", es ging recht schnell.

- Anpassungen in Migrationen waren nötig
- direktes SQL, das railsfied werden musste
- Empfehlung: Abfragen besser komplett agnostisch mit AR-Bordmitteln machen, notfalls geht aber SQL, dass auf MySQL und PostgreSQL gleichermaßen funktioniert.
- Zur Anpassung wurde der Quellcode nach SQL-Keywords und "execute" durchsucht.
- Der Prozess war:
  1. DB in development wechseln
  2. App wieder "bootbar" machen
  3. Specs laufen lassen und durchklicken, um Reste zu finden.
