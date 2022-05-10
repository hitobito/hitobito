# Messages Dispatch
Die Aufgabe der Dispatch Klassen ist der versand von Messages.

## BulkMail Dispatch
Versendet Mails an MailingListen Empfänger. Damit diese Ordentlich zugestellt werden können, müssen folgende Headers gesetzt werden:

| Header      | Definiton                                          | Wert                                |
| ----------- |:-------------------------------------------------- |:----------------------------------- |
| sender      | Absenderadresse von hitobito                       | asdf42@hitobito.example.com            |
| to          | Adresse der MailingList                            | asdf42@hitobito.example.com                  |
| from        | Absenderadresse Original Mail                      | luca@example.com                    |
| Reply-To    | Antwortadresse (falls unterschiedlich zu from)     | luca@example.com                     |
| Return-Path | Wenn unzustellbar zurück an die definierte adresse | luca@example.com                     |

Desweiteren müssen die Empfänger im SMTP Teil `RCPT TO` gesetzt werden. `RCPT TO` steht für `recipient to`.

Return-Path Header: https://stackoverflow.com/a/154794
