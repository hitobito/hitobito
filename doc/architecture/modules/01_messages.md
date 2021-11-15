# Messages

![Aktueller Mailversand](../diagrams/modules/messages.svg)

_Systemübersicht. (Mailclient -> Dispatch to be implemented)_

Mit Hitobito können Nachrichten (Briefe, SMS, Mails) an verschiedene Empfänger gesendet werden. Die Messages werden innerhalb von Hitobito erstellt, danach können diese an externe Dienste weitergegeben werden, oder für den eigengebrauch verwendet werden.

## Abo
Das Model definiert die Empfänger einer Message. Die `MailingList` Objekte werden auch Abos genannt und sind so im UI zu finden. Die Abos lassen auch eine Konfiguration eines Mailchimp dienstes zu. Die `MailingList` wird auf einer Gruppe erstellt, dabei ist konfigurierbar, wie stark mitglieder dieser Gruppe das Abo bearbeiten dürfen.

## Message
Das Message Model definiert die verschiedenen Messages von Hitobito und ist eine Single Table Inheritance ([STI](https://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html)).

| STI Model              | Beschreibung |
|------------------------|-------------------|
| `Message::TextMessage` | Dieses Model definiert eine Nachricht, welche per SMS versendet wird. |         
| `Message::Letter`      | Dieses Model definiert einen Brief, welcher beispielsweise an eine Druckerei gesendet werden kann. |         
| `Message::LetterWithInvoice` | Dieses Model ist ähnlich dem Brief, jedoch ist dies ein Rechnungsbrief. Rechnungsbriefe können verwendet werden um Spendenaufrufe zu erstellen. |         
| `Message::BulkMail` | Das `BulkMail` Model wird für Mails verwendet, dies kann als besipiel für einen Newsletter verwendet werden. |         

### 

## Dispatch













#OLD

------------------------------------------------------------------
## Empfänger
### Modules
#### `People`
Die `People` können einerseits Personen, andererseits auch Unternehmen sein. Das Model hierzu ist das `Person`. Die Unterschiede der beiden sind das Flag `company` welches bei Unternehmen auf `true` gesetzt ist sowie das Attribut `company_name`.

### Models
#### `Person`
Das Model definiert alle Personen/Unternehmen welche in Hitobito vorhanden sind. Messages erhalten immer eine Person als Sender, dabei sind immer eine, oder mehrere Personen, Empfänger.

_Die wichtigsten Attribute des `Person` Models._

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
Das Model definiert die Empfänger einer Message. Die `MailingList` Objekte werden auch Abos genannt und sind so im UI zu finden. Die Abos lassen auch eine Konfiguration eines Mailchimp dienstes zu. Die `MailingList` wird auf einer Gruppe erstellt, dabei ist konfigurierbar, wie stark mitglieder dieser Gruppe das Abo bearbeiten dürfen.

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
Der `MessageRecipient` wird im `Dispatch` erstellt, sobald eine Message versendet wird. Dieser besteht aus den Personen und der Nachricht welche versendet werden. Jeder `MessageRecipient` erhält zudem einen Status, in welchem man den jeweiligen Status des versands einsehen kann. Sollte ein Versand abrupt gestoppt werden, kann mithilfe des Status eingesehen werden, welche Personen einen Nachricht noch nicht erhalten haben. Folglich kann der Versand bei diesen Personen wiederaufgenommen werden. 

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

## Versand
### Dispatch

### Klassen
### `TextMessageDispatch`
Diese Klasse wird für den Versand von SMS Messages verwendet. Der folgende Ablauf wiederspiegelt den Ablauf der `run` Methode innerhalb dieser Klasse.

1. Die `MessageRecipient` Einträge werden erstellt.
2. Die SMS werden versendet. Diese werden in sogenannten Batches* abgearbeitet.
3. Den Status der Message auf `sent` aktualisieren.

### `LetterDispatch`
Diese Klasse versendet Briefe, änhlich wie der SMS dispatch.

### `Messages::DispatchJob`

### Models
### `Message`
Das Message Model definiert die verschiedenen Messages von Hitobito und ist eine Single Table Inheritance ([STI](https://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html)).

| STI Model | Beschreibung |
|----------|-------------------|
| `Message::TextMessage` | Dieses Model definiert eine Nachricht, welche per SMS versendet wird. |         
| `Message::Letter` | Dieses Model definiert einen Brief, welcher beispielsweise an eine Druckerei gesendet werden kann. |         
| `Message::LetterWithInvoice` | Dieses Model ist ähnlich dem Brief, jedoch ist dies ein Rechnungsbrief. Rechnungsbriefe können verwendet werden um Spendenaufrufe zu erstellen. |         
| `Message::BulkMail` | Das `BulkMail` Model wird für Mails verwendet, dies kann als besipiel für einen Newsletter verwendet werden. |         

## Verarbeitung
### Klassen



### `Message::TextMessage`
Diese Klasse ist die Baseclass für alle weiteren Text Nachrichten Schnittstellen (`TextMessageProvider`).

### `Message::TextMessage`
Diese Klasse ist die Baseclass für alle weiteren Text Nachrichten Schnittstellen (`TextMessageProvider`).

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

