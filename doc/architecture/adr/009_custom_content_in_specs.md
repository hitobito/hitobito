# ADR-009 Custom Contents in den tests

Status: **Entscheid**

Entscheid: **Neue Wagons laden nur via seeds.**

## Kontext

Aktuell exisitieren 2 Varianten um custom contents für die tests bereitzustellen

- via fixtures (zb. core `spec/fixtures/custom_contents.yml`)
- via explizitem laden (zb. core, `SeedFu.seed [Rails.root.join("db", "seeds")`])

Beide Varianten in einem Projekt zu haben steht im Widerspruch und führt
zu unterschiedlichen Daten. Schön wäre, wenn wir hier uns auf eine Variante
festlegen und die andere loswerden.

## Optionen

### Laden via fixtures

+ Laden schnell und implizit
- Aufwendige Pflege
- Werden von den seed daten abweichen
- Neue keys gehen mitunter vergessen

### Laden via seeds

+ Anpassungen werden nur an 1 Stelle gemacht
+ In sync mit development Code
- Laden weniger schnell

### Generieren von fixtures aus seeds

+ Anpassungen werden nur an 1 Stelle gemacht


## Kommentar/Advice

Neue Wagons sollen nur noch via Seeds laden. Bei bestehenden Projekten
akzeptieren wir die Doppelgleisigkeit, da der Wechsel zu einer der aufgeführten
Optionen (Fixtures, Seeds oder generiererte Fixtures) zwangsläufig Anpassungen
an der test Suite nach sich ziehen würde.
