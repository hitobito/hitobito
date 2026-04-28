# 2.17
## Features und Improvements
* **Auftrag / Auftragsmangement**
    * **Tab "Positionen":**
        * Inaktive Portfolio- & Dienstleistungs-Einträge werden nun herausgefiltert
* **Zeitfreigabe:** Neu wird die Erinnerung per E-Mail am letzten Arbeitstag des Monats versendet, wenn die Zeiten noch nicht freigegeben wurden.

* **API**: Der Employee-API wurde das Feld `ldapname` hinzugefügt.

# 2.16
## Features und Improvements
* **Auftrag / Auftragsmanagement**
	* **Tab "Positionen"**:
		* Der CSV-Export umfasst auch den ausgeschriebenen Namen der Buchungsposition (#64412)
  		* Link zu betroffenen Leistungen auch bei Zeile 'Total' verfügbar (#64388)
	* **Tab "Leistungen"**:
 		* die Filterung bleibt nach dem Bearbeiten von Leistungen bestehen (#64984)
	* **Tab "Auftrags-Controlling"**:
   		* Beim Öffnen ist standardmässig der Tab "Laufende" geöffnet (#64109)
    * **Tab "Verrechnungs-Controlling"**:
    	* Verrechnungs-Controlling: neue Übersicht zur Anzeige nicht noch verrechneter Leistungen (#64087)
    * * **Tab "Rechnungs-Controlling"**:
      	* Rechnungs-Controlling: Das Listenergebnis kann exportiert werden (#64444)
* **Member Management**
	* Members > Absenzen Übersicht:
 		* Sortierung nach Spalte "übrige Ferien" möglich (#64536)
   		* Filterung nach OE möglich (#64537)
	* Members > Zeit Übersicht: neue Spalte Feriensaldo per Ende Jahr (#64535)
 	* beim Member kann der Member Coach hinterlegt werden (Verwalten > Members > Bearbeiten > Feld "Member Coach") (#64907)
		* hinterlegter Member Coach wird angezeigt unter Members > Memberliste und unter Members > Zeiten (bei letzterem Filterung nach Member Coach möglich)
* **Spesen**:
	* Belege neu als (mehrseitige) PDF möglich. Für den Export werden die PDFs in Bilder konvertiert, jede Seite des PDFs gibt eine Seite im Export. Erste Seite des Spesen-Eintrages enthält den Header, die weiteren dazugehörigen Seiten sind ohne Header. (#64085)

## Bugfixes
* **Member-Management**: Members > Auslastung: Export für aktuellen Zeitraum behoben (#64619)
* **Aufträge**: Der Menü-Eintrag "Aufträge" wird dunkelblau markiert, wenn "Rechnungs-Controlling" und "Verrechnungs-Controlling" geöffnet sind

## Operations
* **Error-Tracking-Tool**: Wechsel von Sentry auf Glitchtip

# 2.15.3

## Bugfixes und Improvements

* **Odoo Sync**: Der nächtliche Sync von Odoo zu Puzzletime wurde repariert (#64796, #64695, #64620)
* **Spesen**: Beim Speichern von Spesen wird der Auftrag wieder gespeichert (#64539)
* **Mehrere Leistungen umbuchen**: Mehrere Leistungen umbuchen funktioniert wieder (#64530)

# 2.15.2

## Bugfixes und Improvements

* **Odoo Sync**: Der nächtliche Sync von Odoo zu Puzzletime wurde repariert
* **Odoo Sync**: Sonderzeichen werden jetzt korrekt übernommen

# 2.15.1

### Bugfixes und Improvements

* **Zeitrapport**: Seitenlayout anpassbar
* **Zeitrapport**: Logikfehler behoben
* **Rechnungsfilter**: Logikfehler behoben
* **Browser**: Fehler beim zurückwechseln im Browser behoben
* **Zeiterfassung**: Zeiterfassung Checkboxen Anzeigefehler behoben, der diese beim Update resettet hat
* **Zeitrapport**: Zeitstempel in Zeitrapport repariert

# 2.15

### Features, Improvements und Bugfixes
(aufgrund der Menge nach Thema sortiert)

* **Zeiterfassung**:
   * Budgetstand anzeigen (#51298):
        * Bei der Auswahl der Buchungsposition zeigt ein farbiger Punkt die Budget-Situation dieser Buchungsposition an (rot = weniger oder gleich 0% offenes Budget, orange = weniger oder gleich 20% offenes Budget, grün = mehr oder gleich 20% offenes Budget). Nach Auswahl der Buchungsposition erfolgt die Anzeige als Balken (Mouse-over auf Balken: Summe geleistete Stunden  (inkl. nicht verrechenbar) / Budget auf Position (Prozent verbraucht ggü. Budget))
    * Interne Bemerkungen (#63818): im Zeiterfassungsformular gibt es ein neues Feld "interne Bemerkungen" z.B. für interne Bemerkungen/Argumentation zur Verrechenbarkeit.
       * Der Feldinhalt wird in den CSV-Export integriert, aber nicht in den Zeitrapport. 
* **Auftrag / Auftragsmanagement**:
   * Übergreifend:
     * UI Probleme die bei der Benutzung von 'Page back' im Browser behoben (z.B. wird das Feld 'Auftrag' nach 'Page Back'nicht mehr dupliziert) (#63952, #63820, #63817, #63994)
   * Tab "Positionen"
        * die Zahlen können für einen gewünschten Zeitraum angezeigt werden. Die Summen der geleisteten Stunden, nicht verrechenbaren Stunden und das noch offene Budget werden gemäss gewähltem Zeitraum berechnet und angezeigt (Szenario: beim Monatsabschluss kann der Budgetstand per Ende letzten Monats angezeigt werden). Die Spalten 'Offenes Budget' und 'geplantes Budget' zeigen die Menge ab dem Folgetag des gewählten Ende-Datums (#63950)
        * Die einzelnen Zellen der Buchungspositionen ('geleistete Stunden' und 'Nicht verrechenbar') enthalten einen Link, welcher zu den entsprechenden Leistungen führt (Wechselt ins Tab 'Leistungen') (#64083)
        * CSV-Export der Buchungspositionen-Ansicht möglich (#64017)
        * Herunterscrollen überdeckt das Navigationsmenü bei Aufträgen mit vielen Buchungspositionen nicht mehr (#64143)
   * Tab "Budget-Controlling"
        * Beim Mouseover werden die Kosten als formattierte Währung angezeigt sowie zusätzlich die Anzahl Stunden, die hinter diesen Kosten stecken (#63923 & #64180)
   * Tab "Leistungen"
        * Das Feld 'Buchungspositionen' ist ein Mehrfachauswahlfeld. Es werden alle gewählten Buchungspositionen übernommen bei Klick auf 'Rechnung erstellen' sowie auch beim Generieren des Zeitrapportes oder CSV-Exports. (#63116)
        * Die Ansicht der Leistungen und der CSV-Export wurde mit der Spalte 'Stundenansatz' ergänzt (#62594)
   * neuer Tab "Kosten"
        * Im neuen Tab 'Kosten' sind alle Spesen und Verpflegungsentschädigungen, die mit dem Auftrag assoziiert sind. Der Tab ist ersichtlich für der/die Auftragsverantwortliche:n des Auftrags und alle User mit dem Flag 'Management' (#62595)
   * Tab "Planung"
        * Neben der Summe der geplanten Stunden zum Auftrag werden auch die geplanten Ressourcen innerhalb des gewählten Zeitraumes angezeigt (oben links bei der Summe sowie in der Tabelle pro Member). Die vorhandenen Titel wurden entsprechend angepasst. Da die verwendete Ansicht der Plan-Daten auf Wochen-Basis funktioniert, können die Werte nur von Mo-Fr angezeigt werden. Um die Konsistenz zu gewährleisten, wurde die Zeitraum-Auswahl auf Mo-Fr eingeschränkt. (#63115)
* **Zeitrapport**
    * Für mehrere Buchungspositionen möglich (#63116):
        * Im Auftrag > Tab "Leistungen" ist der Filter "Buchungsposition" ein Mehrfachauswahlfeld, wodurch ein Zeitrapport für mehrere Buchungspositionen erstellt werden kann, ohne zuerst eine Rechnung erstellen zu müssen
    * Nach Generieren des Zeitrapportes ist das Speichern als PDF möglich (kein PDF-Druck mehr notwendig) (#63194)
    * Ansprechenderes Design umgesetzt und Firmenlogo eingefügt (#63194)
    * Die Summe der im Zeitrapport enthaltenen Leistungen wird nur noch zu unterst auf der letzten Seite angezeigt. Der Filename enthält nun auch den Auswertungszeitraum (#63194)
* **Rechnung erstellen**
    * Zeitraum-Auswahl (Dieser Monat, Letzter Monat, Vorletzter Monat) analog Tab 'Leistungen' möglich (#63118)
    * Beim Rechnung erstellen wird unterhalb der CHF-Summe die Summe der verrechenbaren Stunden, die diesen Betrag ergeben und damit in Rechnung gestellt werden, angezeigt (#63117)
    * Werden im Tab 'Leistungen' die Filter Zeitperiode, Member oder Buchungsposition gesetzt, werden diese bei Klick auf'Rechnung erstellen' für die Rechnung übernommen (#63119)
    * Die Vorschau des Rechnungsbetrages enthält den richtigen Wert gem. der definierten Rechnungsinhalte (#63819)
    * Der Link 'Rechnung erstellen' im Tab 'Rechnungen' wird nur noch angezeigt, wenn der  Benutzer die Berechtigung dazu hat (#64080)
* **Liste Rechnungs-Controlling**
    * Eine neue Übericht über alle erstellten Rechnungen und deren Status. Filterung nach Zeitperiode, OE, Kunde, Auftragsart, Rechnungsstatus, Auftragsverantwortlicher möglich (#63987)
* **Liste "Controlling"**
    * Die Liste 'Controlling' heisst neu Auftrags-Controlling (wegen neuem 'Rechnungs-Controlling') (#63114)
    * Beim Öffnen wird der Filter OE gemäss der beim eingeloggten User hinterlegten OE vorbelegt (#63114)
    * Neu gibt es drei vordefinierte Suchlisten (#63114)
        * Alle (alle Auftragsstatus)
        * Laufende (nur Status 'Bearbeitung')
        * Abgeschlossene (nur Status 'Abgeschlossen')
        * Nur Aufträge mit Zeitenbuchungen oder auch Aufträge ohne Zeitenbuchungen anzeigen zu lassen möglich (#63114)
    * Sortierung nach Spalte 'Budget-Controlling' möglich (#63925)
* **Spesen**
    * In der Liste "Alle Spesen" und im PDF Export der Spesen wird die OE des Members angezeigt (#64084)

# 2.14

### Features
* **Member API**: Zwei neue Felder (city & birthday) hinzugefügt

### Improvements
* **Übersetzungen**: Deutsche Übersetzungen verbessert

# 2.13

### Features
* **Umsatztabelle**: Umsatztabelle neu nach OE des Members gruppierbar (62592)
* **EmpAuftragsmanagement**: Splittansicht bei abgeschlossenen Stunden  (63627)
* **Auftrags-Controlling**: abgeschlossene Aufträge ohne Zeiten werden neu auch angezeigt (62593)

# 2.12

### Bug fixes
* **Charts**: Limits und Beschriftungen in Charts gefixt.
* **Lupe**: Lupen in Zeitbreakdown gefixt
* **Dropdown**: Dropdown gefixt.
* **Join Tables**: Join Tables mit ids versehen um Form input zu erleichtern.
* **Spesen**: Spesen duplizieren gefixt.

# 2.11

### Features
* **QR Code:** QR Code mit Kontaktdaten statt URL [\#176](https://github.com/puzzle/puzzletime/issues/176)

### Improvements

* **Update:** Ruby auf Version 3.2.1 aktualisiert
* **Update:** Rails auf Version 7.1.3 aktualisiert
* **Update:** Alle Dependencies aktualisiert
* **Build Pipeline:** Github Actions werden nun verwendet

# 2.10

### Improvements

* **Login:** Auto-redirect zum SSO login sofern genau 1 SSO Provider konfiguriert ist und localauth deaktiviert ist
* **Sicherheit:** Secure flag auf session cookie gesetzt
* **UX:** Absenztyp Filter wird nun auch für Absenzen Export respektiert

# 2.9

### Improvements

* **Log:** Änderungen an den Funktionsanteilen der Anstellungen werden neu im Members-Log protokolliert
* **Absenzen:** In der Auswertung kann nach Absenztyp gefiltert werden
* **Auslastung:** Verwendet nun die Standard Zeitbereich Auswahl.
* **CSV Detaillierte Auslastung:**
   + Berücksichtigt nun den eingestellten Zeitbereich
   + Berechnung des durchschnittlichen Arbeitspensums korrigiert
   + Spalte hinzugefügt für "bereinigte Projektzeit"

# 2.8

### Features

* **Login:** Login wird auf SSO (Keycloak, Devise) umgestellt
* **Zeitfreigabe:** Neu wird eine Erinnerung per E-Mail versendet, wenn die Zeiten noch nicht freigegeben wurden.

### Improvements
* **Stammdaten:** In den Stammdaten der Members wird neu der vertragliche Arbeitsort geführt
* **Log:** Die Änderungen der Anstellungen (Pensen, Funktionen) wird neu im Members-Log protokolliert

# 2.7

### Features

* **Login:** Unterstützt nun Omniauth mit Keycloak und/oder SAML
* **Rechnungsstellung:** Umstellung auf SmallInvoice APIv2 (vorher v1)
* **Business Intelligence:** Wir können jetzt Verbindung zu einer InfluxDB herstellen, die wichtige Kennzahlen als Timeseries speichert

### Improvements
* **Update:** Update auf Ruby 2.7
* **Exporte:** Die verschiedenen CSV Exporte in einen Controller refactored
* **Journaleinträge:** Jeder kann jetzt Journaleinträge erstellen
* **Rechnungen:** Werden jetzt auf 5 Rappen gerundet
* **Support** X-Sendfile-Header kann jetzt per Umgebungsvariable gesetzt werden
* **Dokumentation:** Das Herokusetup ist jetzt dokumentiert
* **Spesen:** Spesenbelege werden nun beim Hochladen herunterskaliert
* **Kundenauswertung:** Auftrag verlinkt, um schneller hin und her navigieren zu können
* **Mitarbeiter-Stammdaten:**
   + Attribut "Telefon privat" umbenannt in "Mobiltelefon"
   + Anstellungsprozente und Funktionsanteile können nun in 2.5% Schritten konfiguriert werden
   + Neues Attribut "Arbeitsort", verfügbare Werte konfigurierbar unter "Verwalten"
* **Mitarbeiterliste:** Sortierbar gemacht nach Vorname, Nachname
* **Zeiterfassung:** Leerschläge vor und nach der Ticketnummer werden entfernt

### Bug fixes
* **Überzeitexport:** Header sind jetzt aussagekräftiger
* **Verbleibende Arbeitszeit:** Berechnung korrigiert wenn Überstundenkompensationen in der Zukunft liegen

# 2.6

### Features

* **Verpflegungsentschädigung:** Bei der Arbeitszeiterfassung kann zusätzlich angegeben werden, ob die Arbeit beim Kunden vor Ort erfolgte und dazu eine Verpflegungsentschädigung gewünscht wird.
* **Mitarbeiter-Stammdaten:** Ausweisinformationen können nun hinzugefügt werden.
* **Buchungspositionen:** Einstellungen zu Ticket, Von-Bis-Zeiten und Bemerkungen können nicht mehr geändert werden, falls bereits Leistungen ohne diese Angaben erfasst wurden.
* **Buchungspositionen:** Auftrags-Cockpit mit neuen Informationen ergänzt.

### Improvements

* **Usability:** Unter "Members" - "Zeiten" wird die Tabelle standardmässig nach Members der eigenen Organisationseinheit gefiltert, was die Bedienung und Ladegeschwindigkeit massiv erhöht.
* **Usability:** Im Zeiterfassungs-Formular können nun auch alte Zeiteinträge dupliziert werden.
* **Usability:** Auftragsverantwortliche dürfen die AHV-Nummern aller Members einsehen.
* **WebServer:** Mehr Threads für mehr Leistung.
* **Sicherheit:** Updates diverser rubygems aus Sicherheitsgründen.

### Bug fixes

* **Stundenübersicht:** Falsches Total berichtigt.
* **Buchungspositionen:** Automatische Budget-Berechnung beim Eintragen korrigiert.
* **Mitarbeiterliste:** Falsche Berechnung des Jubiläum (Dienstjahre) [\#61](https://github.com/puzzle/puzzletime/issues/61)

# 2.5

### Improvements

* **Layout:** Die Navigationsleiste ist nun sticky [\#29](https://github.com/puzzle/puzzletime/issues/29)

* **Wording:** Mitarbeiter heissen neu Members.

* **Absenzen:** Mit Management-Berechtigung können nun Absenzen der anderen Members gelöscht werden.

* **Zeitfreigabe:** Die Zeitfreigabe wird neu im Log des Members angezeigt.

* **Rechnungen:** Manuelle Rechnung, die im Rechnungsstellungtool editiert wurden, können in PuzzleTime nicht mehr versehentlich überschrieben werden.

* **Mitarbeiterblatt:** Die AHV-Nummer der Members wird nur noch mit Management-Berechtigung angezeigt [\#23](https://github.com/puzzle/puzzletime/issues/23)

* **Umsatzberechnung:** Fälschlicherweise verrechenbar gebuchte Stunden auf Puzzle werden nun nicht mehr mit einbezogen.

* **Umsatz:** Gibt es jetzt als CSV Export.

* **Feiertage:** Neu können alle Feiertage frei konfiguriert werden.

* **Sicherheit:** Updates diverser rubygems aus Sicherheitsgründen.

### Bug fixes

* **Login:** Bei fehlerhaftem Login wird die Meldung nun in der Warnfarbe dargestellt.
* **Wochenübersicht Stunden:** Sollstundenlinie verschiebt sich nicht mehr.
* **Zeitbuchung:** Es kann nun nur noch von 00:00-23:59 gebucht werden um Fehlern vorzubeugen.
* **Budget-Controlling:** Submenü wird nun wieder korrekt dargestellt.
* **Browsersupport:** Projektsuche funktioniert wieder auf IE11.

# 2.4

### Features

* **Spesen:** Neu können in PuzzleTime Spesen hochgeladen und freigegeben resp. abgelehnt werden.
* **API:** Ein neues json:api mit Lesezugriff, vorerst nur für /employees. Unter `/api/docs` ist ein Swagger UI mit der Dokumentation verfügbar.

### Improvements

* **Umsatz:** Auftragsverantwortliche haben nun auch Zugriff auf den Umsatz.

### Bug Fixes

* **Zeiterfassung:** Usability Fehler beim Duplizieren von Zeiteinträgen geflickt [\#28](https://github.com/puzzle/puzzletime/issues/28)
* **Zeiterfassung:** Beim Zeiterfassen mit Firefox kann mit Tab wieder von der Buchungsposition weitergesprungen werden [\#34](https://github.com/puzzle/puzzletime/issues/34)

# 2.3

### Improvements

* **Ruby/Rails:** Auf Ruby 2.5.3 und Rails 5.2.2 aktualisiert
* **Mitarbeiter-Stammdaten:** Neu können bei den Mitarbeitern Nationalitäten und der (Hochschul-)Abschluss erfasst werden.
* **Rechnungen:** Unter Aufträge - In einem einzelnen Auftrag - Rechnungen wurden die Summen verbessert um einen besseren Überblick über bezahlte und offene Stunden zu erhalten.
* **Mitarbeiterlog I:** Unter Verwalten - Mitarbeiter - Log können berechtigte Personen nun nebst den Änderungen am Mitarbeiter auch die Änderungen an den Anstellungen nachverfolgen.
* **Mitarbeiterlog II:** Sofern möglich werden Namen statt IDs der Änderungen angezeigt.
* **Konfigurierbarkeit:** ID der betreibenden Firma, MwST, Währung und Land können nun konfiguriert werden.

### Bug Fixes

* **Wirtschaftlichkeit:** Unter Aufträge - In einem einzelnen Auftrag - Positionen werden in der Berechnung der Wirtschaftlichkeit die stornierten Rechnungen nicht mehr mit einberechnet.

# 2.2

### Features

* **Budget-Controlling I:** Unter Aufträge - Controlling sieht man anhand eines Fortschrittsbalken, wie viele Stunden vom Gesamtbudget schon geleistet wurden. Ein Klick darauf führt ins neue Budget-Controlling Tab des entsprechenden Auftrages.
* **Budget-Controllig II:** Im Budget-Controlling Tab eines Auftrages sieht man anhand eines chicen Balkendiagramms, wann wie viele Stunden geleistet wurden und wie viele Stunden in der Zukunft provisorisch und definitiv geplant sind.
* **Zeitkontrolle:** Zeitfreigabe und -kontrolle ist nun auch für die Auftragsverantwortlichen (unter Aufträge - Meine Aufträge) ersichtlich
* **Mitarbeiterblatt:** Auf dem Mitarbeiterblatt (unter Mitarbeiter - Zeiten - Mitarbeiter auswählen) ist nun die Sollarbeitszeit im entsprechenden Zeitraum ersichtlich.
* **Fremde Arbeitszeiten löschen:** Mit Management-Berechtigung können die Arbeitszeiten anderen Mitarbeiter gelöscht werden. Diese werden per E-Mail darüber informiert, wer wann welchen Eintrag gelöscht hat.

### Bug Fixes

* **Planung:** Planungseinträge gehen nicht mehr verloren, wenn in einem Auftrag ohne Buchungspositionen nachträglich Buchungspositionen erstellt werden
* **Planungswiederholung:** Eine Planungswiederholung kann nun auch bis am 31.12.2018 erstellt werden, denn dieses Datum trifft ausnahmsweise auf die Kalenderwoche 1 des Folgejahres 2019.
* **Mitarbeiterblatt:** Das Mitarbeiterblatt (unter Mitarbeiter - Zeiten - Mitarbeiter auswählen) sieht nun auch gedruckt gut aus und passt auf eine Seite (querformat).
* **Zeiterfassung:** Die Arbeitszeiten können nun auch mit Microsoft Edge erfasst werden [\#3](https://github.com/puzzle/puzzletime/issues/3)

# 2.1

### Features

* **Risikomanagement:** Die Chancen/Risiken werden neu in einem eigenen Tab unter den Aufträgen verwaltet
* **Mehrere Highrise Aufträge:** Auf einem Auftrag können nun mehrere Highrise Aufträge verlinkt werden
* **Zeitkontrolle:** Die Zeitkontrolle kann nun im PuzzleTime unter "Auswertungen" - "Mitarbeit" - "Kontrolle" gemacht werden
* **Jubiläum:** In der Mitarbeiterliste werden nun die Anzahl Dienstjahre der Mitarbeiter angezeigt

### Bug Fixes

* **Volltextsuche:** Volltextsuche der Buchungspositionen geflickt
* **Auslastung:** Auswertung Detailierte Auslastung CSV berücksichtigt nun die korrekten internen Positionen
* **MWST:** PuzzleTime kann nun mit mehreren MWST-Sätzen korrekt rechnen
* **Absenzen:** Die Sichtbarkeit der Absenzen bereinigen

### Improvements

* **Ruby/Rails:** Auf Ruby 2.2.2 und Rails 5.1.2 aktualisiert
* **Performance:** Chrome Memory Leak in Plannings behoben
* **Usability:** Menüstruktur reorganisiert
