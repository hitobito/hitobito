## E-Mail

Hier findest du eine Übersicht sowie die Dokumentation der E-Mail Features von Hitobito

### Mailing Listen / Abos

Hitobito stellt eine simple Implementation von Mailing Listen zur Verfügung. Diese können in der 
Applikation beliebig erstellt und verwaltet werden. Dies geschieht in den Modellen `MailingList` 
und `Subscription`.

Alle E-Mails an die Applikationsdomain (z.B `news@db.jubla.ch`) werden über einen Catch-All Mail 
Account gesammelt. Dabei muss der Mailserver den zusätzlichen E-Mail Header `X-Original-To` setzen, 
welcher den ursprünglichen Empfänger enthält (z.B. `news`). Von der Applikation wird dieser Account 
in einem Background Job über POP3 regelmässig gepollt. Die eingetroffenen E-Mails werden danach wie 
folgt verarbeitet:

1. Verwerfe das Email, falls der Empfänger keine definierte Mailing Liste ist.
1. Sende eine Rückweisungsemail, falls der Absender nicht berechtigt ist.
1. Leite das Email weiter an alle Empfänger der Mailing Liste.

DiDa man aus diversen Gründen (BCC, Mail Aliase) den eigentlichen Empfänger nicht aus dem To: Header lesen kann, muss ein zusätzlicher Header mit der Empfängeradresse vom Mailserver gesetzt werden. Als quasi Standard hat sich für solche Zwecke hier der X-Envelope-to Header etabliert.e Berechtigung, um auf eine Mailing Liste zu schreiben, kann konfiguriert werden. Der Absender 
wird über seine Haupt- oder zusätzlichen E-Mail Adressen identifiziert. Standardmässig können alle 
Personen, welche die Liste Bearbeiten können, sowie die Gruppe, welcher das Abo gehört, E-Mails 
schreiben. Optional können zusätzlich spezifische E-Mail Adressen, alle Abonnenten der Gruppe oder 
beliebige Absender (auch nicht in hitobito erfasste) berechtigt werden. 

Jede Gruppe kann beliebig viele Abos haben, welche optional eine E-Mail Adresse 
haben und dadurch ebenfalls als E-Mail Liste verwendet werden können. Einzelne Personen, jedoch auch 
bestimmte Rollen einer Gruppe oder Teilnehmende eines Events können Abonnenten sein.

#### X-Original-To Header

Da man aus diversen Gründen (BCC, Mail Aliase) den eigentlichen Empfänger nicht aus dem To: Header lesen kann, muss ein zusätzlicher Header mit der Empfängeradresse vom Mailserver gesetzt werden. Als quasi Standard hat sich für solche Zwecke hier der X-Envelope-to Header etabliert.

### Mailversand

Bei folgenden Aktionen werden Mails versendet: (Wagon Features sind hier nicht berücksichtigt)

| Aktion | Mailer Class | DelayedJob | Attachment ? |
| --- | --- | --- | --- |
| Passwort vergessen | via Devise gem | - | nein |
| Passwort Reset / Login erstellen (durch Fremdperson) | Person::LoginMailer | Person::SendLoginJob | nein |
| Zugriffsanfrage Person | Person::AddRequestMailer | Person::SendAddRequestJob | nein |
| Event Bestätigung Teilnahme | Event::ParticipationMailer | Event::ParticipationConfirmationJob | ja |
| Event Abmeldung Teilnahme | Event::ParticipationMailer | Event::CancelApplicationJob | nein |
| Event Einladung Registrierung | Event::RegisterMailer | Event::SendRegisterLoginJob | nein |
| Export der Abonnenten einer Mailingliste| Export::SubscriptionsMailer | Export::SubscriptionsJob | ja |
