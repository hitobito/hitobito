# Entwurfsentscheidungen

Wir führen wichtige Entwurfsentscheidungen als Architecture Decision Records ([ADR](https://adr.github.io/)).
Diese werden als jeweils eigene Datei im Ordner `doc/architecture/adr` abgelegt und hier je nach Status verlinkt.
Momentan arbeiten wir mit den beiden Status _Vorschlag_ und _Abgeschlossen_.
Neuere ADRs werden oben in der Liste eingetragen.

Für den Entwicklungsalltag relevante Informationen sollen in zusätzlichen Orten dokumentiert werden.

## Vorgehen

Architekturrelevante Entscheidungen sollen grundsätzlich mit dem Hitobito Architektur Board abgesprochen werden.
Als architekturrelevant sehen wir unter anderem folgende Aspekte (Liste nicht abschliessend):
- Einführung neuer Konzepte oder grundlegende Änderungen an bestehenden Konzepten
- Neue Gems/Dependencies zum Projekt hinzufügen
- Anpassungen am Entwicklungs-/Buildsetup (Checks, ...)
- ...

Je nach Tragweite sollen diese Entscheidungen hier dokumentiert werden. Das Vorgehen ist wie folgt:
- Eine neue Datei im Ordner `doc/architecture/adr/` erstellen, basierend auf der [ADR Vorlage](./adr/template.md).
  Die nächste freie Nummer wird als Prefix verwendet. Darauf wird die Entscheidung beschrieben und hier unter "Vorschläge" verlinkt.
- Für die Änderungen ein Merge Request erstellen.
- Den Merge Request über den `hitobito-internal` Chat bekannt machen, um das Team zu Rückmeldungen aufzufordern.
  Dabei wird ein zeitnaher Termin festgelegt (ein bis zwei Wochen), bis wann die Entscheidung getroffen werden soll.
- Sobald es soweit ist, wird die neue Datei in den Status "Abgeschlossen" geändert und der Merge Request gemerged.
- Falls der Entscheidungsprozess länger dauert (und wohl nicht so dringend ist), kann der Merge Request auch schon vorher gemerged werden.
- Sobald der Entscheid gefällt ist, wird dieser ebenfalls über dem `hitobito-internal` Chat ans Team kommuniziert.

## Vorschläge

- [003 DB as a Service](./adr/003_db_as_a_service.md)
- [002 Wechsel RDBMS](./adr/002_wechsel_rdbms.md)
- [001 Kundenprojekte als App vs. in Wagon](./adr/001_kundenprojekte_app_vs_wagon.md)

## Abgeschlossen

- [004 S3 Storage](./adr/004_s3_storage.md)
- [005 JSON API](./adr/005_json_api.md)
- [006 ViewComponents](./adr/006_view_components.md)
- [007 Rubocop](./adr/007_rubocop.md)
