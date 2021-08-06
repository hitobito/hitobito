# Hitobito Changelog

## unreleased

*  Service Tokens haben show_full Berechtigung auf Personen (#1355)

## Version 1.26

*  Überarbeitete Kursfilterung, mit wählbarem Datum statt nur jahresbasiert (#1153)

## Version 1.23

*  Layout der OAuth-Dialoge angepasst und Logos ermöglicht (#1044)

## Version 1.22

*  Anlässe und deren Anmeldeangaben können übersetzt werden (#1135, hitobito_sjas#28)
*  automatische Warteliste für Anlässe (hitobito_sjas#27)
*  Tag Verwaltung unter Einstellungen
*  Anmeldungsfragen können auch nur eine Antwort haben (#1079)
*  Adressvervollständigung auf Personen (hitobito_cvp#18)
*  Tägliche Validierung der Adressen einer Person (hitobito_cvp#19)
*  Anlässe können den Teilnehmern erlauben, sich gegenseitig in der Teilnehmerliste zu sehen (#878)
*  Personen / Duplikate zusammenführen (hitobito_cvp#23)
*  Erstellen von Rechungen für Abonnenten von Abos
*  Bugfix: Vergangene Anlässe werden nicht mehr auf der Person angezeigt (#847)
*  Verbesserung der Mailchimp Integration und am Rechnungsmodul
*  Liste "Meine Abos" auf der Person (optional für jede hitobito-Instanz)
*  QR-Code-Rechnungen
*  Icons in der Suche
*  Neue API-Endpoints für Gruppen-Hierarchie und Abos
*  Berechtigungen werden im OAuth-Profil mitgeliefert
*  Eigene OAuth-Autorisierungen können entfernt werden
*  Generelle Validierung von E-Mail Adressen
*  Datenbank kann nun Emoji (also: alles aus Unicode) speichern
*  Bug behoben, der das Übersetzen von Texten in neue Sprachen verhindert hat
*  Personen filtern die einen spezifischen Tag nicht besitzen

## Version 1.21

*  Stackupgrade ruby-2.5, rails-6
*  OIDC für OAuth
*  Mehr Daten in der JSON-API

## Version 1.20

*   Für Seiten und Formulare können Hilfetexte hinterlegt werden
*   Erfassen von mehreren Personen erleichtert ("Speichern und weitere erfassen"-Button)
*   Profilbilder werden bis 512x512 Pixel erlaubt


## Version 1.19

*   Neue Navigation, mit Menü für Mobile
*   Mehrfachaktionen auf Personen
*   API Schnittstelle für Events
*   Service Accounts für API
*   Rechnungen erstellen mit `:finance` Berechtigung
*   Integration mit Mailchimp API
*   Seite für Events mit externer Anmeldung ohne Login
*   Dynamische Spaltenauswahl auf Personen und Teilnehmern
*   Möglichkeit, eigenes Logo pro Gruppe hochzuladen

## Version 1.18

*   Alle Personenfilter sind zusammengefasst und lassen sich abspeichern.
*   Personenfilter erlauben den Gültigzeitszeitraum einer Rolle einzuschränken.
*   Berechtigte Personen können die Applikation als eine andere Personen verwenden.
*   Mailinglisten können an spezifische E-Mail Adressen einer Person verschickt werden.
*   Mehrere Personen können zu einem Haushalt zusammengefasst werden.
*   ICAL Kalender Export für Anlässe.
*   PDF-Export für Personen
*   Grosse Exports werden im Hintergrund heruntergeladen.
*   Technical Information: Starting from Version 1.18.9 you need at least Ruby 2.2

## Version 1.17

*   Export der Abonnenten einer Mailingliste wird im Hintergrund erstellt und per mail versendet


## Version 1.16

*   Vorbedingungen von Kursarten können zusätzlich mit ODER verknüpft werden.
*   Für alle Anlässe lassen sich beliebige Administrationsangaben zu den Teilnehmenden definieren.
*   Anzeige der Hauptebene bei Personenexporten und Teilnehmerlisten.
*   Anlässe können dupliziert werden.
*   Personenfilter nach Qualifikationsdaten und mehreren Qualifikationen.
*   Sichtbarkeit der Anmeldungen auf Kursliste für alle Personen ist pro Kurs konfigurierbar.
*   Aktualisieren der Kontaktdaten bei der Eventanmeldung
*   Festlegen von Pflichtangaben zur Person bei der Eventanmeldung
*   Anmeldestand kann für alle sichtbar gemacht werden


## Version 1.15

*   Neue Rolle "Helfer/-in" für Anlässe.
*   Unterschriften können nun bei allen Anlässen eingefordert werden.
*   Anzeige des Geburtsdatums in Anlassteilnahmelisten.
*   Notizen ebenfalls auf Gruppen möglich.
*   Alle Personen derselben Firma sind unter Person > Mitarbeiter/-innen ersichtlich.
*   Qualifikationen werden in Kursen erst auf Knopfdruck aktualisiert.
*   Anmeldedatum wird bei Anmeldeknopf auf Anlassliste angezeigt.


## Version 1.14

*   Automatisches Ausfüllen der Kurs Beschreibung wenn ein Kurstyp gewählt wird.
*   Admin kann gelöschte Personen in der Volltextsuche finden.
*   Anfrageverfahren wird für gelöschte Personen ebenfalls ausgelöst.
*   Gelöschte Personen können pro Ebene angezeigt werden.
*   Benutzer/-innen können personalisierte Etiketten erstellen.
*   Übername und ein P.P. Post Feld können den Etiketten hinzugefügt werden.
*   Globale Suche nach Anlassnamen und Kursnummern.
*   Excel-Export für Personen und Anlässe.
*   CSV- und Excel-Exporte von Personen mit allen Angaben enthalten aktuelle Qualifikationen.
*   Der Verlauf einer Person zeigt neu die Rollen so an, dass die Gruppen auch die übergeordneten Ebenen anzeigt.
*   Der Verlauf einer Person wird neu nach der Gruppe inkl. übergeordneter Ebenen sortiert.


## Version 1.13

*   Personen können in Mailinglisten nach Tags gefiltert werden.


## Version 1.12

*   Zu Personen können eingeschränkt sichtbare Notizen hinterlegt werden.
*   Personen können eingeschränkt sichtbar getaggt werden.
*   In der Navigation wird der Gruppenkurzname angezeigt, wenn vorhanden.


## Version 1.11

*   Pro Ebene aktivierbare Zugriffsanfragen, falls Personen zu einer fremden Gruppe, Anlass oder Abo hinzugefügt werden.
*   Bei Anlässen können Dateien angehängt werden, welche für alle einsehbar sind.
*   Option, um beim Etikettenexport Mehrfachsendungen zu vermeiden.


## Version 1.10

*   Schnelleres Laden der Seiten dank Turbolinks und Kompression.
*   Tooltips bei langen Gruppennamen.
*   Letzte bearbeitende Person von Anlässen wird gespeichert.
*   Anlass Formular in mehrere Tabs aufgeteilt.


## Version 1.9

*   Land ist neu ein Auswahlfeld.
*   Kursarten haben zusätzliche Text Felder 'Generelle Informationen' und 'Aufnahmebedingungen'.
*   Kurse haben zusätzliches Text Feld 'Aufnahmebedingungen'.
*   Möglichkeit, bei einer PDF Kursanmeldung eine Unterschrift einzufordern.
*   Überarbeitetes Layout der PDF Kursanmeldung.
*   Nicht erfüllte Aufnahmebedingungen werden bei einer Teilnahme angezeigt. Eine Anmeldung ist trotzdem möglich.
*   Beim Hinzufügen zur Kurs Warteliste kann neu ein Kommentar eingegeben werden.
*   Möglichkeit, Personen aufgrund ihrer Qualifikationen zu filtern.
*   Beim Schreiben auf eine Mailing Liste können neu ebenfalls die zusätzlichen E-Mail Adressen sowie die E-Mail Adressen der Gruppe als Absender verwendet werden.
*   Neue Grundberechtigungen für eine Gruppe und alle darunter liegenden Gruppen.
*   Unterstützung für Deployment auf Openshift v2.


## Version 1.8

*   Möglichkeit, den Zugriff auf Anlässe und Kurse unterschiedlich zu berechtigen.


## Version 1.7

*   Möglichkeit beliebige Absender auf Mailinglisten zuzulassen.
*   Unterstützung von internationalen Postleitzahlen.
*   Echtzeitvalidierung der Von-/Bis-Daten bei Anlässen.
*   Hinweis mit Details über die Aktion bei 'Login verschicken'.


## Version 1.6

*   Anzeige der Anzahl gefundenen und nicht sichtbaren Personen auf Personenlisten.
*   Anzeige von beliebigen Informationen beim Login Formular.
*   Beschränkung der Gruppen / Rollen bei Abos auf Gruppe und Untergruppen.


## Version 1.5

*   Rollen in Anlässen können geändert werden.
*   CSV Import erkennt Auswahlwerte in der aktuellen Sprache (z.B. ja/nein anstelle 1/0).
*   Möglichkeit, beim CSV Import Werte in der Datenbank zu ändern.
*   CSV Export für Gruppenanlässe und Kurse.
*   Verschiedene Bug Fixes und Stabilitätsverbesserungen.


## Version 1.4

*   Möglichkeit für Beziehungen zwischen Personen.
*   Neue Grundberechtigungen nur für die aktuelle Ebene.


## Version 1.3

*   Mehrsprachigkeit.
*   Rollenauswahl erfolgt nun auf dem Formular, nicht mehr im Dropdown.
*   Gruppenauswahl der jeweiligen Ebene beim Erstellen von Rollen.
*   Direktes Ändern von Rollen auf Personenlisten.
*   CSV Export aller Untergruppen einer Gruppe.
*   Logging aller Änderungen von Personenattributen.
*   Weitere E-Mail Adressen (analog Telefonnummern) bei Personen und Gruppen.
*   Prominente Gruppennavigation.
*   Anzeige von Gruppe und Ebene bei Rollen.
*   JSON API für Gruppen und Personen.
*   Sortierbare Personen und Teilnehmer Listen.
*   Separat definierbare Qualifikationstypen für Kursleiter.
*   Pflichtfelder für Anlass Fragen.
*   Mehrfachauswahl bei Personen Filter und Abo Listen.
