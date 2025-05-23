# Qualifikationen

Qualifikationen sowie deren Gültigkeiten werden über Qualifikationsarten (`QualificationKind`) konfiguriert.
Dort stehen folgende Parameter zur Vergfügung:

- `validity`: Gültigkeitsdauer in Jahren. Wird für die automatische Berechnung des Enddatums einer Qualifikation verwendet.
- `reactivateable`: Anzahl Jahre nach dem Ablauf der Qualifikation (also nach `finish_at`), während denen eine Qualifikation noch verlängert werden kann.
- `required_training_days`: Anzahl erforderlicher Ausbildungstage, welche (in möglicherweisen mehreren Kursen) absolviert werden müssen, um eine Qualifikation zu verlängern. Details siehe unten.

Qualifikationen sind immer bis zum Ende eines Kalenderjahres gültig. Das `finish_at` wird also immer auf den 31. Dezember gesetzt.

## Erteilen oder Verlängern via Kurse

Über Kursarten (`Event::Kind`) wird konfiguriert, welche Qualifikationsarten ...

- als Vorbedingung eines Teilnehmenden für den Kursbesuch am Kursdatum gültig sein müssen
- bei einem erfolgreichen Kursbesuch neu ausgestellt werden (sowohl für Teilnehmende und für Leitende)
- bei einem erfolgreichen Kursbesuch mit bestehenden Qualifikationen verlängert werden (sowohl für Teilnehmende und für Leitende)

Bei Kursen wird das letzte Kursdatum als Qualifikationsdatum verwendet. Beim Verlängeren einer Qualifikation wird immer eine neue Qualifikationsinstanz mit einem neuem Start- und Enddatum erzeugt. Die ursprüngliche Qualifikation bleibt unverändert.

## Erforderliche Aubildungstage

Falls auf einer Qualifikationsart das Feld "Erforderliche Ausbildungstage" gesetzt ist, werden bestehende Qualifikationen nicht bei jedem Kursbesuch einer entsprechend konfigurierten Kursart verlängert, sondern nur, wenn die Summe der Ausbildungstage von vergangenen Kursen gleich oder grösser als die "Erforderlichen Ausbildungstage" ist.

Dabei werden alle Kurse berücksichtigt, welche die entsprechende Qualifikationsart verlängern und die bis maximal der Anzahl Gültigkeitsjahre der Qualifikationsart vor dem aktuellen Kurs stattgefunden haben. Die Ausbildungstage dieser Kurse (`Event#training_days`) werden dabei ab dem aktuellen Kurs in umgekehrt chronologischer Reihenfolge addiert. Sobald die Anzahl erforderlicher Ausbildungstage erreicht oder überschritten ist, wird die Qualifikation verlängert. Dabei wird das Qualifikationsdatum des chronologisch ersten Kurses (innerhalb der erforderlichen Ausbildungstagen) als Startdatum der neuen Qualifikationsinstanz verwendet, und somit nicht zwingend das Datum des aktuellen Kurses (ausser der aktuelle Kurs dauert bereits gleich lang oder länger als die erforderlichen Ausbildungstage, dann wird die Qualifikation entsprechend per diesem Kurs-Qualifikationsdatum verlängert).

### Beispiel

Die Qualifikationsart der betrachteten Qualifikation definiert eine Gültigkeitsdauer von 6 Jahren, 3 erforderliche Ausbildungstage und 4 Jahre Reaktivierbarkeit.

- 1. Kurs mit 7 Ausbildungstagen im Jahr 2010 führt zu einer neuen Qualifikation, gültig 2010-2016, reaktivierbar bis 2020.
- 2. Kurs mit 1 Ausbildungstag im Jahr 2011 verlängert nichts, da erst 1 Ausbildungstag geleistet wurde.
- 3. Kurs mit 1 Ausbildungstag im Jahr 2014 verlängert nichts, da erst 2 Ausbildungstage geleistet wurde.
- 4. Kurs mit 1 Ausbildungstag im Jahr 2018 verlängert nichts, da der Kurs von 2011 mehr als 6 Jahre her ist und somit dieser Ausbilungstag nicht mehr zählt.
- 5. Kurs mit 2 Ausbildungstagen im Jahr 2019 verlängert die Qualifikation von 2018-2024, da mit diesem und dem Kurs von 2018 die 3 Ausbildungstage erreicht wurden. Das Datum des ersten Kurses dieser Ausbildungstage, also demjenigen von 2018, wird als Startdatum der Qualifikation verwendet. Da die Qualifikation bis 2020 reaktivierbar ist, ist diese Verlängerung noch möglich.

Weitere Beispiele siehe [Specs](../../../spec/domain/event/qualifier_spec.rb).
