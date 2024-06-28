# ADR-003 DB as a Service

Status: **Vorschlag**

Entscheid: **Entscheidung noch offen**

## Kontext

Im Zuge des Wechsels zu OpenShift4 und auch potentiell von MySQL zu PostgreSQL könnte man das RDBMS nicht mehr als Teil der Rails-Applikation, sondern als externen Dienst umsetzen.

## Optionen

- managed DB bei VSHN
  - Angebot muss eingeholt werden
  - hitobito wird mehrheitlich bei VSHN betrieben
- managed DB bei ElephantSQL
  - https://www.elephantsql.com/plans.html
  - kann im GCP in Zürich laufen
- selbst eine "DB as a Service" für die hitobito-Instanzen aufbauen
- weiterhin die DB als Teil der Applikation betreiben

## Konsequenzen

Für die Rails-App selbst ist der Wechsel nicht schwer. Schon jetzt ist die DB "über das Netzwerk" angebunden. Es ändert sich lediglich der Weg zur DB. Weiterhin könnte es noch Auswirkungen auf existentes Tooling haben. Alles, was bisher direkt auf die DB zugreift (ops-scripte) muss potentiell angepasst werden.

## Kommentare/Advice



