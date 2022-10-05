# Messages Dispatch
Die Aufgabe der Dispatch Klassen ist der Versand von Messages.

## BulkMail Dispatch

Versendet E-Mails an MailingListen Empfänger. Folgende E-Mail Headers werden gesetzt:

| Header            | Definiton                                          | Wert                                |
| ------------------|:-------------------------------------------------- |:----------------------------------- |
| to                | Adresse des Abos                                   | abo42@hitobito.example.com          |
| smtp_envelope_from| Adresse des Abos                                   | abo42@hitobito.example.com          |
| from              | Name des Absenders sowie die Aboadresse            | Mike Sender via abo42@hitobito.example.com    |
| Reply-To          | E-Mail des Senders als Antwortadresse              | sender@example.com                     |
| Return-Path       | Wenn unzustellbar zurück an die definierte Adresse | wird vom Mailserver gesetzt (gleich wie smtp envelope from) |
| X-Hitobito-Message-UID | Unique Hitobito Message ID damit wir mögliche Bounce Messages der Sourcenachricht zuweisen können| abcd42 |

Die Empfänger werden via `RCPT TO` gesetzt. (batchweise)
