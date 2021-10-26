# Entwurfsentscheidungen

# JSON API

Das JSON-Format folgt den Konventionen von [json:api](http://jsonapi.org).

# Kundenprojekte: App vs. Wagon

Wie behandeln wir Kundenspezifischen Erweiterungen, welche wenig mit Hitobito zu tun haben, wie z.B. eine simple CRUD-App? 
(Es gibt (noch?) keinen allgemeingültigen Entscheid, wir sammeln mal die Argumente dafür und dagegen)

## Kontext

* Der Kunde möchte oft, dass die User möglichst wenige Tools verwenden müssen.
* Wir wollen negative Auswirkungen auf den Core und andere Kunden (z.B. kompliziertere Entwicklung) vermeiden.

## Variante "ab in den Wagon"

➕ Look&Feel passt automatisch...
➖ ...muss aber nachgezogen werden, wenn L&F im Core ändert
➖ Wir müssen aufpassen, dass wir die zusätzlichen Geschäftsfälle nicht eng an das Hitobito-Datenmodell koppeln, damit Änderungen am Core nicht vermeidbare Änderungen am Wagon verursachen (etwa wegen Berechtigung oder so oder weil wir Models überall im Code rumgeben)
➖ Es kann ein faktisches Vendor-Lock-In bzgl. Hitobito durch spezifische Erweiterungen entstehen

## Variante "eigene App entwickeln"

➕ SSO mit OIDC möglich
➕ Saubere Modularisierung
➕ Mehr Apps, welche die API benutzen, führen zur Weiterentwicklung derselben -> alle profitieren
➖ Zusätzliche Applikation mit Lifecycle, Betrieb(skosten), Deployment...
➖ Aufgabengebiet des WV wird komplexer (oder erfordert ein komplett neues Team mit WV und WV-Planung)
➖ Jetzt müssen wir plötzlich über die API mit Hitobito integrieren, testen und allenfalls die Releases synchronisieren, mit dem Wagon wäre das einfacher

