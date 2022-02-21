# Entwurfsentscheidungen

# JSON API

Das JSON-Format folgt den Konventionen von [json:api](http://jsonapi.org).

# ADR-001 Kundenprojekte: App vs. Wagon

Status: Vorschlag

Wie behandeln wir Kundenspezifischen Erweiterungen, welche wenig mit Hitobito zu tun haben, wie z.B. eine simple CRUD-App?
(Es gibt (noch?) keinen allgemeingültigen Entscheid, wir sammeln mal die Argumente dafür und dagegen)

## Kontext

* Der Kunde möchte oft, dass die User möglichst wenige Tools verwenden müssen.
* Wir wollen negative Auswirkungen auf den Core und andere Kunden (z.B. kompliziertere Entwicklung) vermeiden.

## Optionen

### Variante "ab in den Wagon"

* ➕ Look&Feel passt automatisch...
* ➖ ...muss aber nachgezogen werden, wenn L&F im Core ändert
* ➖ Wir müssen aufpassen, dass wir die zusätzlichen Geschäftsfälle nicht eng an das Hitobito-Datenmodell koppeln, damit Änderungen am Core nicht vermeidbare Änderungen am Wagon verursachen (etwa wegen Berechtigung oder so oder weil wir Models überall im Code rumgeben)
* ➖ Es kann ein faktisches Vendor-Lock-In bzgl. Hitobito durch spezifische Erweiterungen entstehen

### Variante "eigene App entwickeln"

* ➕ SSO mit OIDC möglich
* ➕ Saubere Modularisierung
* ➕ Mehr Apps, welche die API benutzen, führen zur Weiterentwicklung derselben -> alle profitieren
* ➖ Zusätzliche Applikation mit Lifecycle, Betrieb(skosten), Deployment...
* ➖ Aufgabengebiet des WV wird komplexer (oder erfordert ein komplett neues Team mit WV und WV-Planung)
* ➖ Jetzt müssen wir plötzlich über die API mit Hitobito integrieren, testen und allenfalls die Releases synchronisieren, mit dem Wagon wäre das einfacher

## Kommentare/Advice

### mvi 2022-02-21

Bei neuen, recht eigenständigen Erweiterungen sollte man versuchen, diese als eigene Anwendung zu implementieren. Je nach Größe der App könnte es ein eigenes Projekt werden oder nur in einem weiteren Deployment neben hitobito laufen.
