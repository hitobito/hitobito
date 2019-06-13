# Entwicklungs Dokumentation

Diese Dokumente beschreiben verschiedene Aspekte, welche bei der Entwicklung zu beachten sind. Mit `rake doc:dev` kann die eine HTML Datei mit der gesamten Dokumentation generiert werden.

## Inhalt

* [Entwicklungsumgebung](01_setup.md)
* [Deployment](02_deployment.md)
* [Guidelines](03_guidelines.md)
* [Wagons](04_wagons.md)
* [REST API](05_rest_api.md)
* [Jenkins Setup](06_jenkins_setup.md)

Alle Diagramme werden mit [Draw.io](http://draw.io) erstellt und jeweils als Original .xml sowie als .svg abgespeichert.

## Schnittstellen
Es gibt drei Möglichkeiten, Daten aus der MiData zu beziehen:

##### User-Tokens
Mithilfe des User-Tokens kann die JSON-Schnittstelle direkt abgerufen werden. Die Berechtigung ist direkt an die Rollen des Benutzers gebunden.
Mehr Infos hier: [REST API](05_rest_api.md)

##### Service-Accounts
Service-Accounts erlauben einen unpersönlichen Zugriff auf die Applikation. Service-Tokens werden pro Ebene von einer berechtigten Person erstellt und bleiben auch bestehen, wenn diese Person die Gruppe verlässt oder gelöscht wird.
Mehr Infos hier: [Service-Accounts](08_service_accounts.md)

##### OAuth
Durch die OAuth-Implementation können Benutzer-Informationen aus der MiData für andere Dienste bereitgestellt werden. Hierbei muss der Zugriff auf die Daten durch den jeweiligen Benutzer selber freigegeben werden.
Mehr Infos hier: [OAuth](08_oauth.md)