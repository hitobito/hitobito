# Hitobito Changelog

## Version 2.6

- Texte und Hilfetexte verwenden nun den Inhalt einer Fallback Sprache, wenn die gewünschte Sprache leer ist
- Für PDF Generierung wird nun die Schriftart "Noto Sans (Latin, Cyrillic and Greek)" als Fallback Schriftart verwendet (#2372)

## Version 2.6

- Referenznummer von Rechnung wird neu auch auf Empfangsschein angezegit (hitobito_sww#238)
- Sortierung von Rechnungstabelle wird bei PDF Exports beachtet (hitobito_sww#237)
- Beim zusammenführen von Duplikaten werden neu auch Rechnungen, Notizen, Tags, Abos, Familienmitglieder, Event Einladungen und Teilnahmen, Anfragen und Qualifikationen übernommen (hitobito_sww#139)
- Auf der Person können mehrere Adressen erfasst werden (#3264, #3265)
- Eine der weiteren E-Mail Adressen kann für den Rechnungsversand verwendet werden (#3331)
- Login schicken E-Mail wird in der Sprache des Empfängers versendet (hitobito_sww#203)
- Sichtbarkeit von Informationen zur Kontaktperson kann auf Events definiert werden (hitobito_sww#194)
- In den Rechnungseinstellungen kann neu pro Layer eine E-Mail Vorlage definiert werden (hitobito_sww#197)
- Beim zusammenführen von Duplikaten werden neu auch Rechnungen übernommen (hitobito_sww#139)
- Bei externen Anlässen wird besser kommuniziert ob eine Anmeldung möglich ist (hitobito_sww#207)
- Im Länder Dropdown werden alle Länder aufgelistet ohne dass mit der Tastatur gefiltert werden muss (#3364)
- Es können Sammelrechnungen mit Rechnungsposten auf Basis von aktiven Rollen konfiguriert werden (hitobito_swb#18)
- Teilnahmen haben neu einen Knopf um auf das Personenprofil zu navigieren
- Eine Rechnung kann im Originalzustand gedruckt werden, bzw. ohne Mahnungen (hitobito_sww#173)
- E-Mail-Bounces werden erfasst und angezeigt. Nach 3 Bounces wird der Mailversand gestoppt. (hitobito#3053)

## Version 2.5

- Altes Adress-Feld wurde von Personen und Gruppen entfernt, neu gelten die strukturierten Adressfelder (#2226)
- QR-Referenz kann in Rechnungeinstellungen erfasst werden, dieser gilt als Prefix für die Referenznummer auf dem Einzahlungsschein (#3032)
- Filtern nach vergangenen Rollen zeigt nur Personen, welche für den User aktuell sichtbar sind (hitobito_sac_cas#1655)
- Neues Setting mit welchem die Sichtbarkeit von vergangenen Rollen konfiguriert werden kann (Default 0 Tage) (hitobito_sac_cas#1655)
- Mahnungen können nun in den Rechnungseinstellungen übersetzt werden. Sie werden automatisch in der Sprache der jeweiligen Person für jede Rechnung generiert. (hitobito_sww#198)
- Rollen und Teilnahmen auf Mitgliedschaften / Verlauf sind nun (zusätzlich) nach absteigendem Datum sortiert (hitobito_sac_cas#1638).
- Unterscheidung der Filtermöglichkeiten bei inaktiven Rollen nach nie oder zu einer anderen Zeit vorhandenen Rollen (hitobito_sac_cas#1655).
- In der Rechnungsübersicht können neu alle Rechnungen gleichzeitig ausgewählt werden, auch wenn es mehr als die 50 angezeigten gibt (hitobito_sww#172)
- Email's können via Dropdown erneut an Teilnehmer versendet werden (hitobito_sac_cas#1571)
- Der API Endpoint event_kind_categories enthält neu auch das Attribut `order` / Sortierschlüssel.
- Personefilter unterstützt das Filtern nach leeren Attributen (#3148)

## Version 2.4

- Verbesserte Mailchimp Tag Synchronisierung (hitobito_sac_cas#1487)
- PLZ's ausserhalb der Schweiz werden neu anhand des gewählten Landes validiert (hitobito_sac_cas#1488)
- JWT kann als OIDC Access Token konfiguriert werden (hitobito_sac_cas#1110)
- Unterstützung vom login=prompt Parameter im OIDC Authorization Flow (hitobito_sac_cas#1075)
- Bei Anlässen können mehrere Anhänge gleichzeitig hochgeladen werden (hitobito#3017)
- Die Rechnungseinstellungen bieten neu die Möglichkeit, Vorlagen für Rechnungstitel und -text zu definieren. Diese können dann beim Erstellen der Rechnung ausgewählt werden.
- Etikettendruck und Briefexport verwenden nun die gleiche Reihenfolge (#2199)
- Aufwendige Exports (Personen, Abos) werden sequenziell ausgeführt (hitobito_sac_cas#1354)
- Die Rechnungseinstellungen bieten neu die Möglichkeit, den ursprünglichen Rechnungstext bei Mahnungen zu verstecken (hitobito_sww#174)

## Version 2.3

- Ausserhalb von Hitobito angelegte Mailchimp E-Mails werden nicht mehr gelöscht, #2752
- Von Mailchimp via Link abgemeldetet E-Mails nicht unnötig synchronisieren, #1930
- In der JSON:API können Gruppen neu nach layer_group_id (ID der Ebene zu der die Gruppe gehört) und nach parent_id (ID der übergeordneten Gruppe) gefiltert werden.

## Version 2.2

- Für jeden Anhang bei Anlässen, Kursen etc. kann neu individuell ausgewählt werden, ob der Anhang global sichtbar ist (wie bisher) oder ob nur Teilnehmende oder nur das Leitungsteam den Anhang sehen darf (hitobito_sac_cas#486)
- Einführung Mitgliedschaftskonzept (People::Membership) sowie Membership Verification Endpoint (Verschieben vom SKV Wagon in den Core) (hitobito#2511)
- Die Rollentypen werden nun alphabetisch sortiert im Auswahlmenü (hitobito_sac_cas#552)
- Die Volltextsuche sucht bei Personen neu auch nach dem Geburtstag (hitobito_sac_cas#544)
- Haushaltsverwaltung erfolgt auf einer eigenen Seite (hitobito#2616)
- Gruppen mit `static_name` werden nun gemäss aktiver Sprache sortiert dargestellt (hitobito#2677)
- Wagons können die Gruppen Sortierung mittels `sorting_name` überschreiben (hitobito#2677)
- Mittels Attribut auf der OAuth Applikation kann gesteuert werden, ob der Consent Screen bei der Anmeldung via OAuth übersprungen wird (hitobito#2618)
- Eigener JSON:API Endpoint für Rollen (#2243)

## Version 2.1

- JSON:API OpenAPI Dokumentation weist 'extra_fields' korrekt aus (request parameter, entity schema attributes) (hitobito_sac_cas#275)
- Neues Attribut Minimale Teilnehmeranzahl auf Event (hitobito_sac_cas#358)
- Der OIDC /userinfo Endpoint und der OAuth /profile Endpoint geben von nun an immer dieselben (zum Scope passenden) Informationen aus (hitobito#2490)
- Eigener JSON:API Endpoint für Events (hitobito_sac_cas#229)
- Eigener JSON:API Endpoint für Rechnung (hitobito_sac_cas#338)
- Rechnungen können neu auch den Status "Teilzahlung" und "Überzahlung" haben (hitobito_sww#38)
- Einverständnis Erziehungsberechtigte für Selbstregistrierung (hitobito#2404)
- Listen von Rechnungen können nach letztem Zahlungseingang und nach insgesamt bezahltem Betrag sortiert werden (hitobito_sww#147)
- Zahlungen welche nicht einer Rechnung zugewiesen werden konnten, können auf der Seite "Einzelrechnungen" als CSV exportiert werden (#1494)
- Das Familienmitglieder-Feature kann jetzt via Settings im Wagon komplett ausgeschaltet werden
- Upgrade auf Ruby 3.2 (#2242)
- Filtermöglichkeit für Personen mit keinen gültigen, aber reaktivierbaren Qualifikationen, inklusive Stichdatum (hitobito_sac_cas#333)
- Filtermöglichkeit für Personen mit keinen gültigen Qualifikationen, inklusive Stichdatum (hitobito_sac_cas#334)
- Filtermöglichkeit nach inaktiver Rolle (hitobito_sac_cas#335)
- Filtermöglichkeit nach niemals aktiver Qualifikation (hitobito_sac_cas#499)
- Filtermöglichkeit nach abgelaufenen, aber nicht gültigen oder reaktivierbaren Qualifikationen (hitobito_sac_cas#500)

## Version 2.0

- Im Personen Tab "Abos" werden die Abos neu nach der Ebene gruppiert und angezeigt (#2337)
- Auf Abos gibt es neue Optionen im Bereich der selbstständigen Anmeldung. Zusätzlich zu den bisherigen Optionen (niemand kann sich selber anmelden oder beliebige Personen können sich fürs Abo anmelden) gibt es neu die Option "Nur konfigurierte". Ist diese aktiviert, dann können sich nur Personen mit passenden Gruppen/Rollen oder Anlässen für das Abo anmelden. In diesem Modus gibt es ausserdem die Möglichkeit, zwischen Opt-In und Opt-Out zu wählen: Beim neuen Modus Opt-In ist standardmässig niemand fürs Abo angemeldet, und die Gruppen/Rollen und Anlässe dienen ausschliesslich dazu, die erlaubte Zielgruppe für Opt-Ins festzulegen. Opt-Out ist der Modus wie es bisher funktionierte (#2334)
- Nachdem Erstellen einer Person wird sogleich auf mögliche Duplikate geprüft (#2350)
- Rollen mit Start-Datum in der Zukunft können erfasst werden (#2237)
- Eigener JSON:API Endpoint für Gruppen (#2243)
- Personendaten können basierend von Spezifikationen im Wagon automatisiert gelöscht werden. Standardmässig abgestellt (#2106)
- Rollen können mit dem class attribute `terminatable` markiert werden, damit sie von der Person selbstständig beendet werden können (hitobito_sac_cas#133)
- Die Bemerkungen einer Anlassteilnahme können automatisiert nach einer gewissen Zeit gelöscht werden. Standardmässig abgestellt (#2129)
- Personendaten können manuell im "Ohne Rollen" Tab einer Ebene permanent gelöscht werden. (#2105)
- Personen die sich über einen konfigurierbaren Zeitraum nicht eingeloggt haben, können gewarnt und automatisch gesperrt werden (#2069)

## Version 1.31

- Umstellung auf Ruby 3

## Version 1.30

- Der Buchungsbeleg berücksichtigt neu keine Rechnungen mit dem Status "Storniert" (hitobito_sww#136)
- Im Gruppen-Log werden neu auch Änderungen an der Gruppe selber aufgezeichnet (hitobito_sac_cas#73)
- Das Feld "Gestellt am" einer Rechnung oder Sammelrechnung kann neu auch manuell gesetzt werden (hitobito_sww#135)
- Der Gruppen-Tab "Einstellungen" wurde entfernt und die Optionen sind neu in der Bearbeitungsansicht der Gruppe unter dem Tab "Abos" (#2165)
- Einführung von Gruppen-Attributen sowie Migration der Gruppen-Einstellungen (#2165)
- Sammelrechnungen können neu gelöscht werden (#1387)
- Neu gibt es für Gruppen mit aktivierter Selbstregistrierung eine Seite, über welche sich eingeloggte Personen
  in der Gruppe einschreiben können (#2180)
- Logo kann auf Rechnungen angezeigt werden (#hitobito_sww#144)
  - konfigurierbar pro Layer
  - links oder rechts

## Version 1.30

- Die JSON:API liefert für Personen neu auch die Sprache (#2104)
- Der Sicherheits-Tab einer Person kann neu die Gruppen und Rollen, welche `:show_details` Zugriff auf einem haben, auflisten. Merci @cdn64! (hitobito_pbs#257)
- Auf der Personen-Listenansicht können neu via Multiselekt Personen als Abonnenten einem Abo hinzugefügt werden (#2110)

## Version 1.28

- Neu gibt es eine Option, um die Mailadressen von Personenlisten in einem Format spezifisch für Outlook zu exportieren. Merci @simfeld! (#2043)
- Diverse Verbesserungen bei Anlass-Einladungen. Personen die im ganzen Layer Berechtigungen haben, können auch in Anlässen des ganzen Layers andere Personen einladen. Ein neuer Hinweis erklärt, dass die Einladungen nicht per Mail versendet werden. Einladungen können neu sortiert und gelöscht werden, dafür nicht mehr doppelt erfasst. Wenn man eine Einladung ablehnt, wird einem das weiterhin zur Information angezeigt. Merci @nchiapol! (#2045, #2051)
- Tags auf Anlässen können jetzt von denselben Personen entfernt werden, die sie auch erfassen können. Merci @davudevren! (#2050)
- Das Profilbild einer Person kann neu via Klick gross angezeigt werden. Merci @bergerar! (#2044)
- Die Rechnungsliste einer Sammelrechnung zeigt neu standardmässig nicht mehr Rechnungen vom aktuellen Jahr, sondern alle Rechnungen seit Erstellung der Sammelrechnung an. Merci @lukas-buergi! (#2047)
- Die Zwei-Faktor-Authentisierung ist jetzt etwas kulanter, wenn man den Code knapp zu spät eingibt, sowie bei der Verwendung von Hardware OTP Keys. Merci @cleverer! (#2052)
- Die Ansicht um Zwei-Faktor-Authentisierung einzurichten wurde für Mobile optimiert, und man kann die Zwei-Faktor-Authentisierung jetzt auch einrichten, ohne den QR-Code zu scannen, indem man das Secret kopiert. Merci @TeamBattino! (#2046)
- Rollen können neu als `self.basic_permissions_only = true` markiert werden. Dies führt zu eingeschränkten Ansichten und Berechtigungen für die betroffene Person (sww#120)
- Die E-Mail, welche bei der "Passwort vergessen" Funktion gesendet wird, ist neu übersetzt.
- Geburtstag und Geschlecht tauchen nicht mehr doppelt im "Spaltenauswahl"-Export von Personenlisten auf
- Fonts werden direkt von Hitobito ausgeliefert (#1632)
- Die Vorbedingungen einer Kursart können neu als "Muss gültig sein" oder "Muss gültig oder weggefallen sein" deklariert werden. Wenn die Vorbedingung gültig sein muss verhält es sich wie bisher, bei gültig oder weggefallen muss der Teilnehmer die Qualifikation der Vorbedingung besitzen oder jemals besessen haben. Dies gilt unabhängig von der Gültigkeit oder Reaktivierbarkeit der besagten Qualifikation. (#1640)
- Neuer Personentab "Sicherheit", welcher Informationen und Vorgänge zu Sicherheitsmassnahmen aufzeigt und das Passwort einer Person zurücksetzen lässt (benötigt :update Permission auf Person) (#1688)
- Neu können mittels "Buchungsbeleg" Tab bei den Rechnungen die Zahlungen in einem definierbaren Zeitrahmen ausgewertet werden. So werden die Zahlungen ihren Rechnungsartikeln zugeordnet und aufsummiert (hitobito_sww#39)
- Anmeldungen für öffentlich sichtbare Anlässe verbessert (#1775)
- Für variable Spendenaufrufe wird neu der Median über alle Zahlungen im definierten Zeitraum verwendet (hitobito_die_mitte#204)
- Der Buchungsbeleg kann neu zu XLSX oder CSV exportiert werden (hitobito_sww#61)
- Rechnungen können mit Firmennamen gefiltert werden (#1773)
- Personen mit `:finance` Berechtigung können neu bei allen Personen in und unterhalb ihrer Ebene die Rechnungen der Person mittels "Rechnungen" Tab auf dem Profil anzeigen lassen. (hitobito_die_mitte#205)
- In der Kursansicht können neu alle Kurse welche "Anlass ist für die ganze Datenbank sichtbar" aktiviert haben, gefunden werden. (#1813)
- Rechnungsempfänger auf QR Rechnungen wird validiert: muss genau 3 Zeilen enthalten (#1825)
- Erweiterung Personenfilter (#295): Filterung von Personenlisten nach Alter, Geburtsdatum und Geschlecht (merci @simfeld!)
- Neue Filterbedingung "Enthält nicht" (#295)
- OAuth Applikationen können neu spezifischen Zugriff auf nur einzelne API-Endpoints bekommen. Zur Auswahl stehen die Endpoints "group", "person", "event", "mailing_list" und "invoice". (#1399, merci @simfeld!)
- Wird die API mit einem Service Token benutzt, dann kommen jetzt dieselben Felder auf der Person wie mit der veralteten User Authentication (#1460, merci @sniederberger!)
- Bei Zugriffsfehlern in der JSON API wird jetzt konsistent ein JSON-Payload zurückgegeben, statt wie bisher eine HTML-Seite (Seiteneffekt von #1866, ursprünglich gemeldet in der [erweiterten Fehlerliste](https://gist.github.com/carlobeltrame/8dd5b5e6279d91d1e3c181cb9086666a#x-api-should-always-return-json-and-return-the-same-for-parameters-style-and-headers-style-calls) bei der [Einführung der Service Tokens](https://github.com/hitobito/hitobito/issues/586))
- Der API Endpoint eines einzelnen Events enthält neu die URL von Anhängen (#1873)
- Neues "Hitobito Log" einsehbar mit admin permissions unter "Einstellungen" (#1840)
- Neues Bestätigungsmail für Event Voranmeldung (hitobito_cevi#80)
- Einführung neue JSON:API für Personen (#1920)
- Neu kann in den Rechnungseinstellungen im Tab "E-Mail" der Absendername definiert werden, mit dem die Rechnungen dieser Ebene versendet werden (#1893)
- Neu kann auf einer Ebene eine Datenschutzerklärung (DSE) hinterlegt werden. Diese muss, falls vorhanden, bei der Selbstregistrierung, dem Anmelden bei einem Anlass/Kurs oder dem Hinzufügen einer Person auf einer Gruppe akzeptiert werden um fortzufahren. (#1881)
- Personen mit layer_full oder layer_and_below_full können neu Personen, welche in ihren Ebenen unter "Ohne Rollen" erscheinen, per globale Suchfunktion finden und anzeigen. (hitobito_sww#80)
- Anbindung an Nextcloud möglich (#1854)
- Rechnungen werden neu in einem Hintergrundprozess gedruckt (#2014)
- Auf dem Buchungsbeleg sind die einzelnen Positionen nun verlinkt und führen auf eine Auflistung aller Rechnungen, welche die jeweilige Position beinhalten (hitobito_sww#69)

## Version 1.27

- Einzelrechnungen können neu mittels Start- und Enddatum gefiltert werden (hitobito_sww#58)
- Anlässe: Die Kontaktperson wird auf Wunsch per E-Mail über neue Anmeldungen benachrichtigt. Die Benachrichtigung wird auf dem Anlass aktiviert (#1540).
- Jede Person kann jetzt Zwei-Faktor-Authentifizierung mit einer TOTP-App aktivieren. Für einzelne Rollen kann die Zwei-Faktor-Authentifizierung obligatorisch gemacht werden.
- Die Haupt-Mailadresse von Personen mit Login muss neu bestätigt werden nachdem sie geändert wurde (#957).
- Gruppen verfügen nun über eine einfache Mitgliederstatistik auf dem Reiter "Statistiken" auf der Gruppe (hitobito_kljb#4). (Nur bei Verbänden die das bisher noch nicht hatten)
- Der Login-Status (hat kein Login, hat Login, 2FA, E-Mail versendet aber noch nicht akzeptiert) von Personen auf die man Schreibrechte hat kann jetzt als zusätzliche Spalte angezeigt werden (#1296).
- Sprache als Standardattribut auf Person (#1663)
- Anlässe, Kurse, etc. können neu getaggt werden (#1687)
- Es können neu Kalender-Feeds in jeder Gruppe eingerichtet werden. Damit können Anlässe, Kurse, Jahrespläne etc. einer Gruppe in einen externen Kalender (z.B. Google Kalender) eingebunden werden (#1687)
- Es kann neu nach Rechnungen gesucht werden (#1672)
- Introduce new bulk mail stack
- Rechnungen können neu das Total ausblenden (hitobito_sww#26)
- Rollen können beim Erstellen und Editieren ein Start- und Enddatum gesetzt werden. Das Enddatum kann auch in der Zukunft liegen, die Rolle wird dann automatisch an diesem Datum beendet. (#1714)
- Die Kosten-Stelle und das Konto wird für Gruppenrechnungen korrekt gespeichert (gefixt von @maede97) (hitobito_cevi#77)

## Version 1.26

- Gruppen können externe Registrierung aktivieren (Optional) (#1441)
- Personen mit layer_and_below_full Berechtigung dürfen Personenfilter auf tieferen Layern bearbeiten, erstellen & löschen
- Personen können neu als Geschwister angegeben werden (hitobito_kljb#5)
- Liste der vordefinierten Banken für EBICS-Import erweitert (#1427)
- Es wurde neu eine minimale Passwortlänge von 12 Zeichen für neue Passwörter eingeführt, dies entspricht den Empfehlungen von OWASP (#1429)
- Die API unterstützt jetzt, die Gruppen/Rollen, Anlässe und Einzelpersonen auszulesen, welche bei Abos abonniert sind. (danke @Michael-Schaer!) (#1398)
- Teilnehmer können zu Anlässen eingeladen werden (#1276)
- Zahlungen können direkt von Finanzinstitut via EBICS bezogen werden (#1131)
- Personal Access Tokens für die API sind jetzt deprecated. Alle bestehenden Drittapplikationen sollten auf OAuth API Tokens migrieren (siehe https://github.com/hitobito/hitobito/blob/master/doc/development/05_rest_api.md). Diese Entscheidung wurde zusammen mit der hitobito-Community, insbesondere Jubla, CEVI, PBS und SBV gefällt.
- Service Tokens haben show_full Berechtigung auf Personen (#1355)
- Variable Spendenaufrufe können mittels Rechnungsbrief erstellt werden (hitobito_die_mitte#181)
- Mail Client zum verwalten der Mails von Mailing Listen (#1320)
- Überarbeitete Kursfilterung, mit wählbarem Datum statt nur jahresbasiert (#1153)

## Version 1.23

- Layout der OAuth-Dialoge angepasst und Logos ermöglicht (#1044)

## Version 1.22

- Anlässe und deren Anmeldeangaben können übersetzt werden (#1135) (hitobito_sjas#28)
- automatische Warteliste für Anlässe (hitobito_sjas#27)
- Tag Verwaltung unter Einstellungen
- Anmeldungsfragen können auch nur eine Antwort haben (#1079)
- Adressvervollständigung auf Personen (hitobito_cvp#18)
- Tägliche Validierung der Adressen einer Person (hitobito_cvp#19)
- Anlässe können den Teilnehmern erlauben, sich gegenseitig in der Teilnehmerliste zu sehen (#878)
- Personen / Duplikate zusammenführen (hitobito_cvp#23)
- Erstellen von Rechungen für Abonnenten von Abos
- Bugfix: Vergangene Anlässe werden nicht mehr auf der Person angezeigt (#847)
- Verbesserung der Mailchimp Integration und am Rechnungsmodul
- Liste "Meine Abos" auf der Person (optional für jede hitobito-Instanz)
- QR-Code-Rechnungen
- Icons in der Suche
- Neue API-Endpoints für Gruppen-Hierarchie und Abos
- Berechtigungen werden im OAuth-Profil mitgeliefert
- Eigene OAuth-Autorisierungen können entfernt werden
- Generelle Validierung von E-Mail Adressen
- Datenbank kann nun Emoji (also: alles aus Unicode) speichern
- Bug behoben, der das Übersetzen von Texten in neue Sprachen verhindert hat
- Personen filtern die einen spezifischen Tag nicht besitzen

## Version 1.21

- Stackupgrade ruby-2.5, rails-6
- OIDC für OAuth
- Mehr Daten in der JSON-API

## Version 1.20

- Für Seiten und Formulare können Hilfetexte hinterlegt werden
- Erfassen von mehreren Personen erleichtert ("Speichern und weitere erfassen"-Button)
- Profilbilder werden bis 512x512 Pixel erlaubt

## Version 1.19

- Neue Navigation, mit Menü für Mobile
- Mehrfachaktionen auf Personen
- API Schnittstelle für Events
- Service Accounts für API
- Rechnungen erstellen mit `:finance` Berechtigung
- Integration mit Mailchimp API
- Seite für Events mit externer Anmeldung ohne Login
- Dynamische Spaltenauswahl auf Personen und Teilnehmern
- Möglichkeit, eigenes Logo pro Gruppe hochzuladen

## Version 1.18

- Alle Personenfilter sind zusammengefasst und lassen sich abspeichern.
- Personenfilter erlauben den Gültigzeitszeitraum einer Rolle einzuschränken.
- Berechtigte Personen können die Applikation als eine andere Personen verwenden.
- Mailinglisten können an spezifische E-Mail Adressen einer Person verschickt werden.
- Mehrere Personen können zu einem Haushalt zusammengefasst werden.
- ICAL Kalender Export für Anlässe.
- PDF-Export für Personen
- Grosse Exports werden im Hintergrund heruntergeladen.
- Technical Information: Starting from Version 1.18.9 you need at least Ruby 2.2

## Version 1.17

- Export der Abonnenten einer Mailingliste wird im Hintergrund erstellt und per mail versendet

## Version 1.16

- Vorbedingungen von Kursarten können zusätzlich mit ODER verknüpft werden.
- Für alle Anlässe lassen sich beliebige Administrationsangaben zu den Teilnehmenden definieren.
- Anzeige der Hauptebene bei Personenexporten und Teilnehmerlisten.
- Anlässe können dupliziert werden.
- Personenfilter nach Qualifikationsdaten und mehreren Qualifikationen.
- Sichtbarkeit der Anmeldungen auf Kursliste für alle Personen ist pro Kurs konfigurierbar.
- Aktualisieren der Kontaktdaten bei der Eventanmeldung
- Festlegen von Pflichtangaben zur Person bei der Eventanmeldung
- Anmeldestand kann für alle sichtbar gemacht werden

## Version 1.15

- Neue Rolle "Helfer/-in" für Anlässe.
- Unterschriften können nun bei allen Anlässen eingefordert werden.
- Anzeige des Geburtsdatums in Anlassteilnahmelisten.
- Notizen ebenfalls auf Gruppen möglich.
- Alle Personen derselben Firma sind unter Person > Mitarbeiter/-innen ersichtlich.
- Qualifikationen werden in Kursen erst auf Knopfdruck aktualisiert.
- Anmeldedatum wird bei Anmeldeknopf auf Anlassliste angezeigt.

## Version 1.14

- Automatisches Ausfüllen der Kurs Beschreibung wenn ein Kurstyp gewählt wird.
- Admin kann gelöschte Personen in der Volltextsuche finden.
- Anfrageverfahren wird für gelöschte Personen ebenfalls ausgelöst.
- Gelöschte Personen können pro Ebene angezeigt werden.
- Benutzer/-innen können personalisierte Etiketten erstellen.
- Übername und ein P.P. Post Feld können den Etiketten hinzugefügt werden.
- Globale Suche nach Anlassnamen und Kursnummern.
- Excel-Export für Personen und Anlässe.
- CSV- und Excel-Exporte von Personen mit allen Angaben enthalten aktuelle Qualifikationen.
- Der Verlauf einer Person zeigt neu die Rollen so an, dass die Gruppen auch die übergeordneten Ebenen anzeigt.
- Der Verlauf einer Person wird neu nach der Gruppe inkl. übergeordneter Ebenen sortiert.

## Version 1.13

- Personen können in Mailinglisten nach Tags gefiltert werden.

## Version 1.12

- Zu Personen können eingeschränkt sichtbare Notizen hinterlegt werden.
- Personen können eingeschränkt sichtbar getaggt werden.
- In der Navigation wird der Gruppenkurzname angezeigt, wenn vorhanden.

## Version 1.11

- Pro Ebene aktivierbare Zugriffsanfragen, falls Personen zu einer fremden Gruppe, Anlass oder Abo hinzugefügt werden.
- Bei Anlässen können Dateien angehängt werden, welche für alle einsehbar sind.
- Option, um beim Etikettenexport Mehrfachsendungen zu vermeiden.

## Version 1.10

- Schnelleres Laden der Seiten dank Turbolinks und Kompression.
- Tooltips bei langen Gruppennamen.
- Letzte bearbeitende Person von Anlässen wird gespeichert.
- Anlass Formular in mehrere Tabs aufgeteilt.

## Version 1.9

- Land ist neu ein Auswahlfeld.
- Kursarten haben zusätzliche Text Felder 'Generelle Informationen' und 'Aufnahmebedingungen'.
- Kurse haben zusätzliches Text Feld 'Aufnahmebedingungen'.
- Möglichkeit, bei einer PDF Kursanmeldung eine Unterschrift einzufordern.
- Überarbeitetes Layout der PDF Kursanmeldung.
- Nicht erfüllte Aufnahmebedingungen werden bei einer Teilnahme angezeigt. Eine Anmeldung ist trotzdem möglich.
- Beim Hinzufügen zur Kurs Warteliste kann neu ein Kommentar eingegeben werden.
- Möglichkeit, Personen aufgrund ihrer Qualifikationen zu filtern.
- Beim Schreiben auf eine Mailing Liste können neu ebenfalls die zusätzlichen E-Mail Adressen sowie die E-Mail Adressen der Gruppe als Absender verwendet werden.
- Neue Grundberechtigungen für eine Gruppe und alle darunter liegenden Gruppen.
- Unterstützung für Deployment auf Openshift v2.

## Version 1.8

- Möglichkeit, den Zugriff auf Anlässe und Kurse unterschiedlich zu berechtigen.

## Version 1.7

- Möglichkeit beliebige Absender auf Mailinglisten zuzulassen.
- Unterstützung von internationalen Postleitzahlen.
- Echtzeitvalidierung der Von-/Bis-Daten bei Anlässen.
- Hinweis mit Details über die Aktion bei 'Login verschicken'.

## Version 1.6

- Anzeige der Anzahl gefundenen und nicht sichtbaren Personen auf Personenlisten.
- Anzeige von beliebigen Informationen beim Login Formular.
- Beschränkung der Gruppen / Rollen bei Abos auf Gruppe und Untergruppen.

## Version 1.5

- Rollen in Anlässen können geändert werden.
- CSV Import erkennt Auswahlwerte in der aktuellen Sprache (z.B. ja/nein anstelle 1/0).
- Möglichkeit, beim CSV Import Werte in der Datenbank zu ändern.
- CSV Export für Gruppenanlässe und Kurse.
- Verschiedene Bug Fixes und Stabilitätsverbesserungen.

## Version 1.4

- Möglichkeit für Beziehungen zwischen Personen.
- Neue Grundberechtigungen nur für die aktuelle Ebene.

## Version 1.3

- Mehrsprachigkeit.
- Rollenauswahl erfolgt nun auf dem Formular, nicht mehr im Dropdown.
- Gruppenauswahl der jeweiligen Ebene beim Erstellen von Rollen.
- Direktes Ändern von Rollen auf Personenlisten.
- CSV Export aller Untergruppen einer Gruppe.
- Logging aller Änderungen von Personenattributen.
- Weitere E-Mail Adressen (analog Telefonnummern) bei Personen und Gruppen.
- Prominente Gruppennavigation.
- Anzeige von Gruppe und Ebene bei Rollen.
- JSON API für Gruppen und Personen.
- Sortierbare Personen und Teilnehmer Listen.
- Separat definierbare Qualifikationstypen für Kursleiter.
- Pflichtfelder für Anlass Fragen.
- Mehrfachauswahl bei Personen Filter und Abo Listen.
