# Schnittstellen
Es gibt drei Möglichkeiten, Daten aus hitobito zu beziehen:

## JSON-Schnittstelle mit persönlichem Token
User können persönliche Zugangs-Tokens generieren und einer externen Applikation mitteilen, welche dann im Namen des Users die JSON-Schnittstelle nutzen kann. Die Applikation hat dabei dieselben Berechtigungen wie der Benutzer.
Mehr Infos auf englisch hier: [JSON API](json_api.md)

## JSON-Schnittstelle mit Service Account
Service Accounts ermöglichen es, für eine externe Applikation einen eigenen Account mit bestimmten Berechtigungen zu erstellen, mit dem sie dann die JSON-Schnittstelle nutzen kann. Service Accounts werden pro Ebene von einer berechtigten Person erstellt und bleiben auch bestehen, wenn diese Person die Gruppe verlässt oder gelöscht wird.
Mehr Infos auf englisch hier: [Service Accounts](../../../07_service_accounts.md)

## OAuth
Hitobito is an OAuth 2.0 provider, meaning that an external application can authenticate users via hitobito (usually in the form of a "Login via hitobito" feature, similar to Google and Facebook etc.). The external application can then query information about the user, if the user has granted this permission. OAuth authentication also allows the external application to use the JSON API. The external application has the same permissions as the user.
More info: [OAuth](../../../08_oauth.md)

## OpenID Connect (OIDC)
OpenID Connect (OIDC) is possible with hitobito. The implementation is not yet described.
