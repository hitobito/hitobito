# Ticket Workflow

Dieses Dokument beschreibt den Workflow von Tickets innerhalb von Hitobito, welche im [Github Project](https://github.com/orgs/hitobito/projects/14/views/1) geführt werden.

Der Prozess besteht aus folgenden Schritten:
1. Konzeption
2. Refinement
3. Umsetzung
4. Review
5. Closing
6. Release

## Eingang der Anforderung

Neue Anforderungen können über die folgenden Kanäle eingehen:

- Help-Tickets
- Github-Issue (Diskussion)
- Offerte
- Community-Meetings
- Bug-Reports
- Tech/Security-Issues

## Konzeption

Aus der Offerte werden vom PO/PL die entsprechenden Epics erstellt. Inhalt kann aus der Offerte übernommen werden. Weiter können Anforderungen von Kunden eine gute Grundlage bieten. Falls bereits absehbar können einzelne kleinere Issues erstellt werden. Diese Issues werden zum Epic verweisen.

- Lead: **PO**, mit Support von Dev mit Kundenkontakt
- Outcome: **Epics**
- Spalte: **Backlog**

Beispiel: https://github.com/hitobito/hitobito_die_mitte/issues/8

## Refinement

Sobald die Epics definiert sind, wird mit dem Kunden ein Termin vereinbart, in welchem die Epics zusammen mit einem Entwickler besprochen werden. Im Nachgang erfahren die Epics vom Entwickler ein erstes Refinement. Dabei erhalten sie detaillierte Tech-Specs und werden in "mundgerechte" Issues heruntergebrochen. Innerhalb des Refinement wird auch die Umsetzung festgehalten.

Zuweilen kommt es vor, dass bei einem Issue eine grössere Diskussion entsteht über die beste Umsetzung, Fragen geklärt werden etc. Bei diesen Issues ist es jeweils sehr Aufwändig, die Entscheidungen nachzuvollziehen. In solchen Fällen sollen ein "Folge-Issue" erstellt werden, welches die Entscheidungen zusammenfasst und übersichtlich aufbereitet.

Beim Refinement kann festgelegt werden, ob nach dem Merge ein Review auf der Integration durchgeführt werden soll bevor das Issue dem Kunden übergeben wird. Dies soll in der ToDo Liste aufgeführt werden.

- [Definition of Ready](./definition_of_ready.md)
- [Issue Template](https://github.com/hitobito/.github/blob/main/.github/ISSUE_TEMPLATE/feature.md)
- Lead: **Dev** mit Kundenkontakt, für Rückfragen: PO
- Outcome: **Issues**
- Spalten: **Development Backlog** / **Refinement** / **Ready**

Sobald das Refinement abgeschlossen ist und der Kunde die Umsetzung frei gegeben hat, wird das Issue in die `Ready`-Spalte verschoben.

## Umsetzung

Ein Dev wählt das oberste Ticket im Status `Ready`, weist dieses sich selbst zu und setzt es in den Status `In Progress`, um es zum implementieren.

Sobald das Feature vollständig umgesetzt ist, wird ein Pull Request erstellt, das Issue in den Status `Implemented` verschoben und die Zuweisung entfernt.

- [Definition of Done](./definition_of_done.md)
- Lead: **Dev**
- Outcome: **Pull Requests**
- Spalte: **In Progress**

## Code-Review

Implementierte Tickets werden von einem zweiten Dev reviewt. 

- Falls noch Anpassungen nötig sind, wird das Ticket wieder dem ursprünglichen Dev zugewiesen und in den Status `In Progress` gesetzt.
- Wenn alles ok ist, merged diese:r die dazugehörigen PR. Das Ticket wird vom Github Workflow automatisch in den Status `Review Integration` gesetzt. Sofern in der Ticket ToDo Liste nichts erwähnt ist, liegt es im Ermessen der mergenden Person, ob ein Review auf Integration angebracht ist. Andernfalls kann das Ticket direkt ins `Closed` verschoben werden.

Falls der Pull Request nur einen Commit enthält, kann dieser über Rebase in den Master gemerged werden. Bei mehreren Commits wird ein Merge Commit bevorzugt. Falls die einzelnen Commits keine Ticket Referenz haben, muss diese zwingend im Merge Commit enthalten sein.

- Lead: **Reviewer** (4-Augen-Prinzip)
- Outcome: **Review**
- Spalte: **Implemented**

## Review Integration

Für Tickets im Status `Review Integration` wurde beim Refinement oder beim Merge des PR entschieden, dass der Change auf der Integrationsumgebung getestet werden soll, before das Ticket dem Kunden übergeben wird.

Es sollen alle Use Cases aus dem Ticket mit angemessenen Rollen getestet werden. Wenn das Review zufriedenstellend ausfällt, wird das Ticket in den Status `Closed` gesetzt, andernfalls wird das Ticket wieder geöffnet, dem ursprünglichen Dev zugewiesen und in den Status `In Progress` gesetzt. 

## Closed

Diese Tickets sind bereit für die Abnahme durch den Kunden. Der Abnahmeprozess ist je nach Kunde unterschiedlich.

- Lead: **Dev**
- Outcome: **Geschlossenes Issues**
- Spalte: **Closed**

## Released

Der produktive Release erfolgt in Absprache mit dem Kunden. Dies geschieht über den entsprechenden PO.

- Lead: **PO**, Umsetzung Wochenverantwortlicher
- Outcome: **Produktiver Release**
- Spalte: **Released**
