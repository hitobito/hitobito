# ADR-010 Transifex mit mode `sourceastranslation`

Status: **Entscheid**

Entscheid: Die Übersetzungen werden von Transifex mit dem mode `sourceastranslation` bezogen.

## Kontext

- Wir pflegen die Deutschen Texte in den Rails i18n YAML Dateien im Projekt Repo.
- In Transifex sind die Deutschen Texte der Master für die anderen Sprachen, d.h. Deutsch (`de`) ist die _Source
  Language_. Die Source Language kann mit unserer Transifex Subscription nicht in Transifex angepasst werden.
- Während dem Release Prozess werden die `keys` und Texte der Source Language mit den YAML Dateien aus dem Repo
  aktualisiert. Danach werden die Texte der anderen in Transifex konfigurierten Sprachen als YAML Dateien
  heruntergeladen und ins Repo
  committed.

## Optionen

Die Übersetzungen können von Transifex mit verschiedenen Modi bezogen werden:

- `onlytranslated`: Es sind nur keys in den heruntergeladenen YAML Dateien enthalten, die eine Übersetzung in der
  jeweiligen Sprache haben. Wenn keys fehlen, wird dies von Rails i18n entsprechend der konfigurierten Fallbacks
  behandelt.
- `sourceastranslation`: Es sind in den heruntergeladenen YAML Dateien alle keys der Source Language enthalten. Für keys
  ohne Übersetzung in der jeweiligen Sprache wird jeweils der Text der Source Language (also Deutsch) verwendet. Somit
  übernimmt Transifex die Fallback Behandlung, die feingranularere Fallback Logik von Rails i18n kommt nicht zum
  Einsatz.
- `default`: Dies ist ein Alias für `onlytranslated`.

## Kommentare/Advice

### di 2025-11-07

Ursprünglich wurden die Übersetzungen mit dem `default` mode bezogen, also implizit mit `onlytranslated`. Es gab
wiederholt Probleme damit, Transifex hat die YAML Dateien mit leeren Strings für nicht übersetze keys generiert. Dies
führte dazu, dass Rails i18n keine Fallbacks anwenden konnte und leere Strings angezeigt wurden. Daher wurde auf den
`sourceastranslation` mode gewechselt. Damit wird zwar auch Rails i18n Fallbacks ausgehebelt, aber es ist
sichergestellt, dass immer ein Text (entweder übersetzt oder der Deutsche Text) vorhanden ist. 
