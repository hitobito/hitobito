# Messages
Das Messages Modul beinhaltet alle Teile der Kommunikation via Briefen und SMS.

![Aktueller Mailversand](../diagrams/modules/messages.svg)

_Systemübersicht. (Mailclient -> Dispatch to be implemented)_

## Empfänger
### Modules
#### `People`
Die `People` können einerseits Personen, andererseits auch Unternehmen sein. Das Model hierzu ist das `Person`. Der sprechende Unterschied der beiden ist das Flag `company` welches bei Unternehmen auf `true` gesetzt ist und das Attribut `company_name`.

### Models
#### `Person`
Das Model definiert alle Personen welche in Hitobito vorhanden sind. Messages erhalten immer eine Person als Sender, dabei wird immer eine, oder mehrere Personen empfänger sein.

TODO: Tabelle anpassen

| Attribut | Beschreibung |
|----------|-------------------|
| id | Das ist die beschreibung |         
| additional_information | Das ist die beschreibung |
| address | Das ist die beschreibung |
| company | Das ist die beschreibung |          
| company_name | Das ist die beschreibung |
| country | Das ist die beschreibung |
| email | Das ist die beschreibung |
| first_name | Das ist die beschreibung |
| last_name | Das ist die beschreibung |
| title | Das ist die beschreibung |
| town | Das ist die beschreibung |
| zip_code | Das ist die beschreibung |
| creator_id | Das ist die beschreibung |
| last_label_format_id | Das ist die beschreibung |
| primary_group_id | Das ist die beschreibung |
| updater_id | Das ist die beschreibung |

#### `MailingList`
Das Model definiert die Empfänger einer Message. Auch Abos genannt und so im UI zu finden. Die Abos lassen auch eine Konfiguration eines Mailchimp dienstes zu.

TODO: Tabelle anpassen

| Attribut | Beschreibung |
|----------|-------------------|
| id | Das ist die beschreibung |         
| group_id | Das ist die beschreibung |         
| additional_sender | Das ist die beschreibung |
| anyone_may_post | Das ist die beschreibung |
| delivery_report | Das ist die beschreibung |          
| description | Das ist die beschreibung |
| main_email | Das ist die beschreibung |
| name | Das ist die beschreibung |
| publisher | Das ist die beschreibung |
| subscribers_may_post | Das ist die beschreibung |

#### `MessageRecipient`

## Versand
### Message

### Dispatch

### Klassen
### `TextMessageDispatch`

### `LetterDispatch`
Diese Klasse versendet Briefe. Bevor dies geschieht werden die MessageRecipients der des Briefes erstellt, danach werden Batches* erstellt.

### `Messages::DispatchJob`

### Models
### `Message`
Dieses Model ist eine Single Table Inheritance.


## Verarbeitung
### Klassen
### `LetterWithInvoice`
Der Rechnungsbrief wird in dieser Klasse erstellt.

### `TextMessageProvider::Base`
Diese Klasse ist die Baseclass für alle weiteren Text Nachrichten Schnittstellen (`TextMessageProvider`).

### `TextMessageProvider::Aspsms`
Aspsms ist ein Dienst welcher eine API bietet mit welcher man SMS an viele Empfänger senden kann. Diese Schnittstelle verwendet Hitobito zum versenden von SMS an Gruppenmitglieder. Die Aspsms Klasse vererbt die `TextMessageProvider::Base` Klasse.

### Models


## Extern
Extern definiert alle Teilsysteme der Messages welche nicht direkt von Hitobito genutzt/verwendet werden aber dennoch in den gesamtablauf integriert sind.

### Druckerei
Die Druckerei hat den Auftrag Digitale Serienbriefe welche von Hitobito erstellt werden, auf Papier auszudrucken. Dabei werden die Briefe von Hitobito erstellt, die Druckerei erhält den link von welchem sie das PDF oder wahlweise eine CSV Datei beziehen kann. Der Benutzer kann im UI den Druckauftrag aktivieren indem die Druckerei aus den Personen auswählt wird. 

## Glossar
Mit *-versehene Wörter, werden in diesem Glossar genauer erklärt.

| Ausdruck | Erklärung |
|----------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| Batches  | Vordefinierte Menge von Messages welche versendet werden müssen. Messages werden in Batches von z.b. 15 Nachrichten abgearbeitet/versendet.   |

