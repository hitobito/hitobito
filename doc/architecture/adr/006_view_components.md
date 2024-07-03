# ADR-000 View Components

Status: **Vorschlag**

Entscheid: **Wir verwenden View Components nur sehr sparsam**

View Components helfen, komplexe Partials besser zu strukturieren. Allerdings haben wir auch bereits andere Methoden im Einsatz (Helpers, Decorators, POROs für Views).
Damit der Wildwuchs nicht allzu gross wird, bleiben reguläre Partials die primäre Wahl.
Nur falls die Logik in einem Partial mehr Raum einnimmt als das Markup, kann auf ViewComponents umgestellt werden. Idealerweise wird dabei auch ein weiterer Dev* konsultiert.


## Kommentare/Advice

### pz 2024-06-28

Wir haben bereits etliche Methoden im Einsatz (Helpers, Decorators, POROs für Views).
Eine weitere Technologie erhöht primär die Komplexität. Dinge werden noch unterschiedlicher gelöst als bisher.
