# Email Versand

Der Aktuelle E-Mail Versand beinhaltet verschiedene `MailRelay` und `RecurringJob` Klassen. Diese gewährleisten die Funktionalität des Mail Versands - diese Architektur wir nun umgebaut, in eine neue.

![Aktueller Mailversand](diagrams/modules/messages-bulk-mail.svg)

_BulkMail Klassendiagramm_

## Ausgangslage

Hitobito bietet die Funktionalität Mails zu versenden. Damit dies funktioniert werden Mails, Mailinglisten zugeordnet. Möchte ein Benutzer also eine Mail versenden, muss dieses Mail an eine Mailingliste gerichtet werden. Dies funktioniert kurzgesagt so: 

1. Der Benutzer erstellt auf einer Gruppe ein neues Abo. In diesem wird die `Mailinglisten Adresse` definiert.
2. Der Benutzer sendet die Mail welche an die Gruppenmitglieder gehen soll, and die vorher definierte `Mailinglisten Adresse` (meine-liste@unser-hitobito.com)
3. Sobald das Mail abgesendet wurde, landet es im `Catch-All Konto` von Hitobito.
4. Der `RecurringJob::MailRelayJob` lädt dieses aus dem `Catch-All Konto` und gibt die Mail der `MailRelay::List` Klasse.
5. Diese sendet mithilfe der `relay()` Methode und der `MailRelay::BulkMail` Klasse das Mail batchweise (in Grössen von z.B. 15 Mails je Batch) an Personen der Gruppe.

## Änderungen

Der Email Versand in Hitobito besteht aus zwei Teilen, einerseits aus den `Retriever` und andererseits aus
den `Dispatch` Jobs. Diese zusammen bilden das Grundkonstrukt welches in Hitobito verwendet wird um Mails zu versenden. Siehe [Dokumentation Messages](modules/01_messages.md).

