# Abos (mailing_lists)

Hitobito stellt eine simple Implementation von Mailing Listen zur Verfügung.
Diese können in der Applikation beliebig erstellt und verwaltet werden. Dies
geschieht in den Modellen `MailingList` und `Subscription`.

Alle E-Mails an die Applikationsdomain (z.B `news@db.jubla.ch`) werden über
einen [Catch-All](https://de.wikipedia.org/wiki/Catch-All) Mail Account gesammelt. Von der Applikation wird dieser Account
in einem Background Job über POP3 regelmässig gepollt. Die eingetroffenen
E-Mails werden danach wie folgt verarbeitet:

1. Verwerfe das Email, falls der Empfänger keine definierte Mailing Liste ist.
2. Sende eine Rückweisungsemail, falls der Absender nicht berechtigt ist.
3. Leite das Email weiter an alle Empfänger der Mailing Liste.

⚡ Man kann aus diversen Gründen (BCC, Mail Aliase) den eigentlichen Empfänger
nicht aus dem `To` Header lesen. Aus diesem Grund muss der Mailserver den
`X-Original-To` Header setzen, welcher den ursprünglichen Empfänger enthält
(z.B. `news@db.example.com`). Es wird immer nur der erste `X-Original-To` Header
verarbeitet.

Berechtigung, um auf eine Mailing Liste zu schreiben, kann konfiguriert werden.
Der Absender wird über seine Haupt- oder zusätzlichen E-Mail Adressen
identifiziert. Standardmässig können alle Personen, welche die Liste bearbeiten
können, sowie die Gruppe, welcher das Abo gehört, E-Mails schreiben. Optional
können zusätzlich spezifische E-Mail Adressen, alle Abonnenten der Gruppe oder
beliebige Absender (auch nicht in hitobito erfasste) berechtigt werden.

Jede Gruppe kann beliebig viele Abos haben, welche optional eine E-Mail Adresse
haben und dadurch ebenfalls als E-Mail Liste verwendet werden können. Einzelne
Personen, jedoch auch bestimmte Rollen einer Gruppe oder Teilnehmende eines
Events können Abonnenten sein.

## Mail-Versand

* Wie oben erwähnt landen sämtliche E-Mails an die Domain einer Instanz (z.B. db.hitobito.com) in einem einzelnen Postfach. 
* Über einen [Cron Job](https://github.com/hitobito/hitobito/blob/master/app/jobs/mail_relay_job.rb) wird in einem definierten Intervall (Standardmässigässig jede Minute) dies Postfach auf neue Mails gecheckt. 
* Kann ein E-Mail einer Mailingliste zugeordnet werden, nehmen wir dieses E-Mail wie es ist entgegen und passen vor dem Versand an die Empfänger des Abos einige Headers an:

[Mail Gem](https://rubygems.org/gems/mail)

### 1. Precendence und List

- ['Precedence'] = 'list'
- ['List-Id'] = list_id

[Code](https://github.com/hitobito/hitobito/blob/master/app/domain/mail_relay/bulk_mail.rb#L67)

### 2. Sender

Setzen von Sender auf Bounce Adresse (abo_name-bounces+hans.muster=example.com@db.hitobito.com)

Da wir die E-Mail in Hitobito entgegen nehmen und dann wieder an alle Empfänger eines Abos versenden ist es wichtig das wir die Domain der Hitobito Instanz verwenden. Aus diesem Grund generieren wir eine spezielle Bounce Adresse welche den Abonamen und die E-Mail des Absenders enthält.

- [Sender Rewriting Scheme](https://de.wikipedia.org/wiki/Sender_Rewriting_Scheme)
- [Sender Policy Framework](https://de.wikipedia.org/wiki/Sender_Policy_Framework)
- [Code](https://github.com/hitobito/hitobito/blob/master/app/domain/mail_relay/bulk_mail.rb#L67)

### 3. SMTP Envelope From (smtp MAIL FROM beim Senden der E-Mail)

Setzen von smtp_envelope_from auf Bounce Adresse (abo_name-bounces+hans.muster=example.com@db.hitobito.com)

[Code](https://github.com/hitobito/hitobito/blob/master/app/domain/mail_relay/bulk_mail.rb#L72)

[Envelope Sender](https://de.wikipedia.org/wiki/Envelope_Sender)

### Mail Headers

E-Mail Headers einer Nachricht die beim Empfänger angekommen ist:

```
...
From: hans.muser@example.com
Sender: abo_name-bounces+hans.muster=example.com@db.hitobito.com
To: abo_name@db.hitobito.com
Subject: Besprechung vom 31.03.2021 - Einladung & Traktanden
...
```
