# Messages Dispatch

Die Aufgabe der Dispatch Klassen ist der Versand von Messages.

## BulkMail Dispatch

Versendet Mails an Abo (MailingList) Empfänger.

Folgende Mail Headers werden für den Versand gesetzt:

| Header      | Definiton                                          | Wert                                |
| ----------- |:-------------------------------------------------- |:----------------------------------- |
| sender      | Absenderadresse Hitobito Abo                       | lists-asdf42@hitobito.example.com            |
| to          | Adresse der MailingList (aus Source/Original Mail)                           | asdf42@hitobito.example.com                  |
| from        | Absenderadresse (aus Source/Original Mail)                      | luca@example.com                    |
| Reply-To    | Antwortadresse     | luca@example.com                     |
| Return-Path | Wenn unzustellbar zurück an die definierte adresse | luca@example.com                     |

Empfänger werden via SMTP `RCPT TO` gesetzt. (BCC)
