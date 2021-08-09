# Entwicklungs-Dokumentation

> For English version see below

Diese Dokumente beschreiben verschiedene Aspekte, welche bei der Entwicklung zu beachten sind. Mit `rake doc:dev` kann die eine HTML Datei mit der gesamten Dokumentation generiert werden.

## Inhalt

* [Development](01_basics.md)
* [Deployment](02_deployment.md)
* [Guidelines](03_guidelines.md)
* [Wagons](04_wagons.md)
* [Jenkins Setup](06_jenkins_setup.md)
* [Frontend & Assets](09_webpacker.md)

Alle Diagramme werden mit [Draw.io](https://draw.io) erstellt und jeweils als Original .xml sowie als .svg abgespeichert.

## Schnittstellen
Es gibt drei Möglichkeiten, Daten aus hitobito zu beziehen:

### JSON-Schnittstelle mit persönlichem Token
User können persönliche Zugangs-Tokens generieren und einer externen Applikation mitteilen, welche dann im Namen des Users die JSON-Schnittstelle nutzen kann. Die Applikation hat dabei dieselben Berechtigungen wie der Benutzer.
Mehr Infos auf englisch hier: [REST API](05_rest_api.md)

### JSON-Schnittstelle mit Service Account
Service Accounts ermöglichen es, für eine externe Applikation einen eigenen Account mit bestimmten Berechtigungen zu erstellen, mit dem sie dann die JSON-Schnittstelle nutzen kann. Service Accounts werden pro Ebene von einer berechtigten Person erstellt und bleiben auch bestehen, wenn diese Person die Gruppe verlässt oder gelöscht wird.
Mehr Infos auf englisch hier: [Service Accounts](07_service_accounts.md)

### OAuth
Hitobito ist ein OAuth 2.0 Anbieter, das heisst dass eine externe Applikation Benutzer via hitobito autentifizieren kann ("Anmelden mit hitobito", ähnlich wie das Google, Facebook, etc. anbieten). Die externe Applikation kann danach Informationen über den Benutzer aus hitobito abfragen wenn der Benutzer dies selber freigibt. Die OAuth-Anmeldung ermöglicht es auch, dass die externe Applikation die JSON-Schnittstellen im Namen des Users nutzen kann. Die Applikation hat dabei dieselben Berechtigungen wie der Benutzer.
Mehr Infos auf englisch hier: [OAuth](08_oauth.md)

### OpenID Connect (OIDC)
OpenID Connect (OIDC) ist mit hitobito möglich. Die Implementation ist noch nicht  beschreiben.

# Developer documentation (English)

These documents describe different aspects that need to be considered when developing. Using `rake doc:dev`, an HTML file with the complete documentation can be generated.

## Contents

* [Development environment](01_setup.md)
* [Deployment](02_deployment.md)
* [Guidelines](03_guidelines.md)
* [Wagons](04_wagons.md)
* [Jenkins Setup](06_jenkins_setup.md)

All graphics are created using [Draw.io](https://draw.io) and are stored as original .xml as well as .svg files.

## Interfaces
There are three ways to get data out of hitobito:

### JSON API with personal token
Users can generate personal access tokens and give them to an external application, which can then use the JSON API. The external application has the same permissions as the user.
More info: [REST API](05_rest_api.md)

### JSON API with service account
Service accounts allow to create a dedicated account with certain permissions for an external application. Using this account, the external application can then access the JSON API. Service accounts are created on a layer by an authorized person, and also persist once this person leaves the group or is deleted.
More info: [Service accounts](07_service_accounts.md)

### OAuth
Hitobito is an OAuth 2.0 provider, meaning that an external application can authenticate users via hitobito (usually in the form of a "Login via hitobito" feature, similar to Google and Facebook etc.). The external application can then query information about the user, if the user has granted this permission. OAuth authentication also allows the external application to use the JSON API. The external application has the same permissions as the user.
More info: [OAuth](08_oauth.md)

### OpenID Connect (OIDC)
OpenID Connect (OIDC) is possible with hitobito. The implementation is not yet described.
