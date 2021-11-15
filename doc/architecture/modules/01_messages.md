# Messages

![Systemübersicht](../diagrams/modules/messages-overview.svg)

_Systemübersicht._

Mit Hitobito können Nachrichten (Briefe, SMS, Mails, usw...) an verschiedene Empfänger gesendet werden.

## Abo
![Systemübersicht](../diagrams/modules/messages-abo.svg)

_Klassendiagramm des Abos._

Damit Nachrichten Empfängern gesendet und zugeordnet werden können, verwendet man in Hitobito sogenannte Subscriptions, also Abonnements. Mit diesen wird sichergestellt, dass Personen oder Gruppen Abos haben können.


### `Person` Model
Das Model definiert alle Personen/Unternehmen welche in Hitobito vorhanden sind. 

### `Group` Model
Das Group Model definiert alle Gruppen welche in Hitobito existieren. Jede Gruppe enthält mehere, eine oder keine Person/Rolle.

### `MailingList` Model
Das Model ist eines der zentralsten Elemente in den Messages, denn mithilfe der Subscriptions können so den Personen/Rollen die Abonnemente zugewiesen werden. Die `MailingList` Objekte werden auch Abos genannt und sind so im UI zu finden. Die Abos lassen auch eine Konfiguration eines Mailchimp dienstes zu. Die `MailingList` wird auf einer Gruppe erstellt, dabei ist konfigurierbar, wie stark mitglieder dieser Gruppe das Abo bearbeiten dürfen.

### `MessageRecipient` Model
Der `MessageRecipient` wird im `Dispatch` erstellt, sobald eine Message versendet wird. Dieser besteht aus den Personen und der Nachricht welche versendet werden. Jeder `MessageRecipient` erhält zudem einen Status, in welchem man den jeweiligen Status des versands einsehen kann. Sollte ein Versand abrupt gestoppt werden, kann mithilfe des Status eingesehen werden, welche Personen einen Nachricht noch nicht erhalten haben. Folglich kann der Versand bei diesen Personen wiederaufgenommen werden.

## Message
![Systemübersicht](../diagrams/modules/messages.svg)

_Klassendiagramm der Messagetypen_

Das Message Model definiert die verschiedenen Messages von Hitobito und ist eine Single Table Inheritance ([STI](https://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html)).

| STI Model              | Beschreibung |
|------------------------|-------------------|
| `Message::TextMessage` | Textnachricht |         
| `Message::Letter`      | Brief |         
| `Message::LetterWithInvoice` | Rechnungsbrief |         
| `Message::BulkMail` | Mail |         

### `Message::TextMessage`
Dieser Typ ist eine SMS (Textnachricht)

### `Message::Letter`
Der Message::Letter ist ein Brief 

### `Message::LetterWithInvoice`
Ein Brief, an welchem man zusätzlich noch Rechnungen beifügen kann.

### `Message::BulkMail`
Eine Mail Nachricht. Muss zum versenden an eine spezifische Emailadresse gesendet werden, welche an ein Abo angebunden ist. Das Mail landet danach in einem Catch-all Konto, bis es versendet wird.

### `TextMessageProvider::Base`
Diese Klasse ist die Baseclass für alle weiteren Textnachricht-Schnittstellen.

### `TextMessageProvider::Aspsms`
Aspsms ist ein Dienst welcher eine API bietet mit welcher man SMS an viele Empfänger senden kann. Diese Schnittstelle verwendet Hitobito zum versenden von SMS an Gruppenmitglieder. Die Aspsms Klasse vererbt die `TextMessageProvider::Base` Klasse.


## Dispatch
Der Dispatch erstellt für jede Message die `MessageRecipients`. Danach wird die Nachricht gesendet und die Status auf den `MessageRecipients` aktualisiert.

### `TextMessageDispatch`
Der Versand der SMS erfolgt mittels HTTP-API von ASPSMS. 

### `LetterDispatch`
Diese Klasse versendet Briefe, änhlich wie der SMS dispatch.

### `Messages::DispatchJob`

### Druckerei
Die Druckerei hat den Auftrag Digitale Serienbriefe welche von Hitobito erstellt werden, auf Papier auszudrucken. Dabei werden die Briefe von Hitobito erstellt, die Druckerei erhält den link von welchem sie das PDF oder wahlweise eine CSV Datei beziehen kann. Der Benutzer kann im UI den Druckauftrag aktivieren indem die Druckerei aus den Personen auswählt wird. 

## Glossar
Mit *-versehene Wörter, werden in diesem Glossar genauer erklärt.

| Ausdruck | Erklärung |
|----------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| Batches  | Vordefinierte Menge von Messages welche versendet werden müssen. Messages werden in Batches von z.b. 15 Nachrichten abgearbeitet/versendet.   |

