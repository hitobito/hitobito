
## Wesentliche Funktionen

* Open Source Webapplikation für grössere, dezentral organisierte Verbände.
* Verwaltung umfangreicher, hierarchischer Strukturen entsprechend den vordefinierten Gruppentypen 
eines Verbandes.
* Führen von Mitgliedern mit verschiedenen Rollen in den jeweiligen Gruppen. Alle Mitglieder können 
potentielle Benutzende sein. Ihre Zugriffsrechte werden durch die Rollen definiert. Änderungen an
 Personbezogenen Daten werden protokolliert.
* Organisation von Anlässen und Kursen. Dies beinhaltet Anmeldungen, Teilnehmendenverwaltung, 
Prüfung von Vorbedingungen und Erteilung von Qualifikationen.
* Führen und Betreiben von Mailing Listen mit individuell und/oder automatisch zusammengestellten 
Empfängern.
* Beliebige verbandsspezifische Erweiterungen in Plugins basierend auf einer einheitlichen 
Basisapplikation. Z.B. Bestandesmeldungen oder Kursreporting.
* Import und Export von Personen- und Anlassdaten als CSV.
* Abfrage von Personen- und Gruppendaten über ein JSON REST API.
* Volltextsuche über alle Personen und Gruppen.


## Qualitätsziele

* _Flexibilität_: Die Applikation muss an spezifische Verbandsstrukturen anpassbar und um beliebige 
Funktionalität erweiterbar sein.
* _Bedienbarkeit_: Auch sporadische Benutzende sollen die Applikation ohne Schulung verwenden können.
* _Sicherheit und Datenschutz_: Es muss sichergestellt werden, dass Benutzende nur auf für sie 
bestimmte Bereiche des Verbandes zugreifen können.
* _Performance_: Ein einfacher Seitenaufruf sollte maximal 0.5 Sekunden dauern, komplexere Abfragen 
maximal 2 Sekunden. Als Grössenordnung kann die Applikation eine halbe Million Personen in tausend 
Gruppen enthalten.
