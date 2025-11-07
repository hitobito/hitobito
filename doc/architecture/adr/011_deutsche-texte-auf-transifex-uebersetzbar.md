# ADR-011 Deutsche Texte auf Transifex übersetzbar

Status: **Entscheid**

Entscheid: Deutsche Texte können in Transifex nach `de_XX` (z.B. `de_CH`) übersetzt werden und im Deploy Prozess wird
`de` durch diese ersetzt.

## Kontext

- `de` wird in Transifex als Source Language verwendet und kann von den Übersetzern nicht angepasst werden.
- Es muss eine andere locale verwendet werden, um Deutsche Texte in Transifex übersetzbar zu machen.
- Die Transifex Übersetzungen werden im Deploy Prozess von Transifex mit dem mode `sourceastranslation` bezogen und ins
  Repo committed. Siehe auch ADR-010.

## Optionen

1. In Rails die locale `de` mit `de_XX` ersetzen:
  - Rails verwendet die "übersetzten" Deutschen Texte aus Transifex. Das I18n Fallback Handling könnte weiterhin die
    `de` Locale verwenden für fehlende Übersetzungen.
  - Es braucht Anpassungen in der Applikation, z.B. am Sprachselektor und beim Generieren der routes wenn in der URL
    immer noch `de` statt `de_XX` stehen soll.
2. Im Deploy Prozess die `de` YAML Dateien durch die `de_XX` Varianten ersetzen:
  - Die Deploy Scripte müssen angepasst werden, so dass beim Bauen des App Images die `de` YAML Dateien durch die
    `de_XX` Varianten ersetzt werden (dabei muss auch der locale key in der YAML Datei umgeschrieben werden).
  - In der Applikation sind keine Anpassungen nötig, es wird weiterhin `de` als locale verwendet. Dabei ist es
    essentiell, dass die `de_XX` YAML Dateien in Transifex immer vollständig sind und es keine fehlenden Übersetzungen
    geben darf da kein Fallback auf das originale `de` stattfinden kann. Die Übersetzungen müssen daher von Transifex
    zwingend mit dem Modus `sourceastranslation` bezogen werden. Dies ist durch die Umsetzung des ADR-010
    sichergestellt.

## Kommentare/Advice

### di 2025-11-07

Die 2. Variante benötigt keine Anpassungen der Applikation und ist somit weniger aufwendig umzusetzen.
