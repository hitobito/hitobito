# ADR-013 Entkoppelung von Übersetzungen und Releases

Status: **Vorschlag**

Entscheid: **Offen**

Aktuell werden die Übersetzungen während des Deployment verwaltet. Wir können transifex direkt mit Github verbinden und so Übersetzungen und Releases unabhängig voneinander managen.

## Kontext

Bei einem Integration-Release werden die Quellen hochgeladen und die Übersetzungen geholt. Bei einem Production-Release werden nur Übersetzungen geholt. In beiden Fällen werden die Dateien in git gespeichert und nachher in das Repo gepusht.

Release einer neuen Version und Pflege der Übersetzungen im Source-Repository gehören nicht direkt zusammen.

Eine Option ist, die von Transifex angebotene Integration mit Github zu verwenden. Diese überwacht das jeweils verbundene Repository auf Änderungen an den Quelldateien und importiert diese automatisch. Es wird nur der Hauptintegration-Branch (aktuell `master`) betrachtet. Bei neuen Übersetzungen in Transifex kann ein PR (mit einem sprechenden Prefix) eröffnet werden. Solange dieser nicht gemerged wird, kommen weitere Änderungen auf den gleichen PR.

Es können folgende Aspekte konfiguriert werden:
- zu betrachtende Quelldatei(en) und zu betrachtender Branch
- ob ein PR eröffnet wird oder direkt committed werden soll
- unteres Limit für den Übersetzungsgrad, ab dem eine Datei in den PR aufgenommen werden soll.
- Prefix für den PR

Anpassungen an den Übersetzungen direkt im Sourcecode werden nicht übernommen und müssen wie bisher manuell mit `tx push --translations --all` hochgeladen werden. Änderungen an diesem Ablauf sind nicht Teil dieses ADR.

Die Bindung an Transifex als Übersetzungstool ändert sich nur wenig, es wird nur die Koppelung von Release und Abgleich der Übersetzungsdateien gelockert. Was aktuell passiert, wenn transifex während eines Release nicht verfügbar ist, ist nicht bekannt.

Die Umstellung kann nach und nach gemacht werden, da auch mit der Integration weiterhin transifex die Quelle der Wahrheit für Übersetzungen bleibt. Sobald die Integration mit transifex vorhanden ist, kann das Release-Script angepasst werden.

## Optionen

### Nutzung der transifex-Integration

#### Vorteile
- Trennung von Release und Übernahme der Übersetzungen in den Source.
- Nachvollziehbarkeit durch PRs

#### Nachteile
- ein Entwickler muss sich um den PR kümmern
- wenn das Übersetzungslimit zu hoch gewählt wird, können bereits vorhandene Dateien wieder gelöscht werden.

#### Aufwände
- Alle Wagons müssen umgestellt werden
- kann nach und nach passieren

### aktuelle Integration mit bin/release belassen

#### Vorteile
- Übersetzungen werden auf jeden Fall geholt

#### Nachteile
- Wenn Feature-Branches von Wagons deployed werden, werden Übersetzungen in den master vom Core geschrieben.
- Übersetzungen werden meist erst beim Release geholt
- Jeder Release (auch nur ein Bugfix) holt vielleicht unpassende Übersetzungen, dies kann bei der Nutzung der Github Action aktuell nicht verhindert werden.

#### Aufwände
- evtl Verwirrung, warum die Übersetzungen geändert haben.

### komplett manuelle Verwaltung der Übersetzungen

#### Vorteile
- komplette Kontrolle über Zeitpunkt und Umfang der Synchronisation

#### Nachteile
- es kann leicht vergessen werden, weil es bisher automatisiert war

#### Aufwände
- vermutlich wird es eine WV-Aufgabe und reduziert damit unser Wartungsbudget

## Kommentare/Advice
