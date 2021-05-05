## E-Mail

Hier findest du eine Übersicht sowie die Dokumentation der E-Mail Features von Hitobito

[Abos / Mailing Listen](abo_mails.md)

### Mailversand

Bei folgenden Aktionen werden Mails versendet: (Wagon Features sind hier nicht
berücksichtigt)

| Aktion | Mailer Class | DelayedJob | Attachment ? |
| --- | --- | --- | --- |
| Passwort vergessen | via Devise gem | - | nein |
| Passwort Reset / Login erstellen (durch Fremdperson) | Person::LoginMailer | Person::SendLoginJob | nein |
| Zugriffsanfrage Person | Person::AddRequestMailer | Person::SendAddRequestJob | nein |
| Event Bestätigung Teilnahme | Event::ParticipationMailer | Event::ParticipationConfirmationJob | ja |
| Event Abmeldung Teilnahme | Event::ParticipationMailer | Event::CancelApplicationJob | nein |
| Event Einladung Registrierung | Event::RegisterMailer | Event::SendRegisterLoginJob | nein |
| Export der Abonnenten einer Mailingliste| Export::SubscriptionsMailer | Export::SubscriptionsJob | ja |
