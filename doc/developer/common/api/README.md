# API

Es gibt drei Möglichkeiten, Daten aus hitobito zu beziehen:

### JSON-Schnittstelle mit persönlichem Token
User können persönliche Zugangs-Tokens generieren und einer externen Applikation mitteilen, welche dann im Namen des Users die JSON-Schnittstelle nutzen kann. Die Applikation hat dabei dieselben Berechtigungen wie der Benutzer.
Mehr Infos auf englisch hier: [JSON API](json_api.md)

### JSON-Schnittstelle mit Service Account
Service Accounts ermöglichen es, für eine externe Applikation einen eigenen Account mit bestimmten Berechtigungen zu erstellen, mit dem sie dann die JSON-Schnittstelle nutzen kann. Service Accounts werden pro Ebene von einer berechtigten Person erstellt und bleiben auch bestehen, wenn diese Person die Gruppe verlässt oder gelöscht wird.
Mehr Infos auf englisch hier: [Service Accounts](service_accounts.md)
