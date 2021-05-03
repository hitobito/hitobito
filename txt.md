Das Generieren des PDFs eine Beispiel Rechnungsbrief (Logo, Einzahlungschein,
2000 Zeichen Text) für Unterschiedliche Anzahl Empfänger hat folgende
Laufzeiten: 


| Empfänger | Laufzeit (Sekunden)|
----------------------------------
| 10   | 1.2 |
| 100  | 3.8 |
| 1000 | 45  |
| 2000 | 120 |
| 4000 | 384 |



Die Zeit geht im wesentlichen für das Rendern des PDFs drauf. Unsere PDF
Bibliothek bietet die Möglichkeit statischen Inhalt wiederzuverwenden (stamping). 
Dadurch wird die Performance massgeblich verbessert.


| Empfänger | Laufzeit (Sekunden)|
----------------------------------
| 10    | 0.7  |
| 100   | 1.0  |
| 1000  | 4.2  |
| 2000  | 8.3  |
| 4000  | 14.9 |
| 10000 | 36 |
| 50000 | 36 |

Zudem skaliert das Rendering so annähernd linear. Für einen equivalenten Brief
mit 100.000 Empfängern wird somit einen Laufzeit von ca 300 Sekunden (6 Minuten
erwartet)
