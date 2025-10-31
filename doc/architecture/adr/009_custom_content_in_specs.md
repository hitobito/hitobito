# ADR-009 Custom Contents in den tests

Status: **Vorschlag**

Entscheid: **Offen**

## Kontext

Aktuell exisitieren 2 Varianten um custom contents für die tests bereitzustellen

- via fixtures (zb. core `spec/fixtures/custom_contents.yml`)
- via explizitem laden (zb. core, `SeedFu.seed [Rails.root.join("db", "seeds")`])


Beide Varianten in einem Projekt zu haben steht im Widerspruch und führt
mitunter zu unterschiedlichen Daten. Schön wäre, wenn wir hier uns auf eine
Variante festlegen und die andere loswerden.


## Optionen

### Laden via fixtures

+ Müssen nicht explizit geladen werden
+ Laden schnell
- Müssen explizit gepflegt werden, geht vergessen
- Eher aufwendiges Pflegen von Übersetzungen

### Explizites Laden in der spec

+ Anpassungen werden nur an 1 Stelle gemacht
- Laden weniger schnell
- Müssen aktuell explizit geladen werden

### Implizites Laden via rake task (zb. `db:test:prepare`)

+ Müssen nicht explizit geladen werden
- Eventuell Anpassung an test setup (docker, pipeline) notwendig
- Eventuell Probleme mit nicht transktionalen specs

### Explizities Laden der Seeds in der Suite (z.B. `spec/support/load_custom_contents.rb`)

+ an einer zentralen Stelle je Wagon eingebunden
+ kann pro Wagon angepasst werden, um dependencies abzudecken
+ keine Anpassung im Test-Setup nötig
- Eventuell Probleme mit nicht-transaktionalen Specs
- Laden (einmalig) weniger schnell

Specs, die die CustomContents verändern und danach wieder zurückrollen, sollten als schlecht isoliert betrachten und korrigiert werden.

## Kommentar/Advice

Ich denke die nachhaltigste Variante wäre das Laden via rake task, da der
grossteil (alle?) unserer tests transaktional sind.
