# Abos (mailing_lists)

Hitobito stellt eine simple Implementation von Mailing Listen zur Verfügung.
Diese können in der Applikation beliebig erstellt und verwaltet werden. Dies
geschieht in den Modellen `MailingList` und `Subscription`.

Alle E-Mails an die Applikationsdomain (z.B `news@db.jubla.ch`) werden über
einen [Catch-All](https://de.wikipedia.org/wiki/Catch-All) Mail Account gesammelt. Von der Applikation wird dieser Account
in einem Background Job über IMAP regelmässig gepollt. Die eingetroffenen
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

## Konfiguration

Mit Release 1.27 (Frühling 2022) wurde ein neuer Mail Stack eingeführt. Die Konfiguration für eingehende Mails erfolgt über die datei `config/mail.yml`. Als Vorlage dient `config/mail.yml.example`. Ist die `config/mail.yml` vorhanden, wird der neue Mail Stack aktiviert. 
Der alte Mail Stack ist immer noch vorhanden und wird aktiviert wenn der Mailempfang via die Umgebungsvariable `RAILS_MAIL_RETRIEVER_CONFIG` konfiguriert ist. 

## Mail-Versand

* Wie oben erwähnt landen sämtliche E-Mails an die Domain einer Instanz (z.B. db.hitobito.com) in einem einzelnen Postfach. 
* Über den [Retriever](https://github.com/hitobito/hitobito/blob/master/app/domain/mailing_lists/bulk_mail/retriever.rb) wird in einem definierten Intervall (Standardmässigässig jede Minute) dies Postfach auf neue Mails gecheckt. 
* Kann ein E-Mail einer Mailingliste zugeordnet werden, nehmen wir dieses E-Mail wie es ist entgegen und passen vor dem Versand an die Empfänger des Abos einige Headers an:

Die Source Mail wird für die Weiterverarbeitung in ein [Mail](https://rubygems.org/gems/mail) Objekt instanziert.

### Sender Attribute

[Envelope Sender](https://de.wikipedia.org/wiki/Envelope_Sender) wird auf die Mailadresse des Abos gesetzt. (abo_name@db.hitobito.com)

Da wir die E-Mail in Hitobito entgegen nehmen und dann wieder an alle Empfänger eines Abos versenden ist es wichtig das wir die Domain der Hitobito Instanz verwenden. [Sender Policy Framework](https://de.wikipedia.org/wiki/Sender_Policy_Framework)

Die E-Mail Headers `Reply-To` sowie `Return-Path` setzen wir auf den Absender des Source Mails. (hans.muster@example.com). `From` bleibt aus dem Source Mail bestehen.

### Mail Headers

E-Mail Headers einer Nachricht die beim Empfänger angekommen ist:

```
...
From: hans.muster@example.com
Sender: abo_name@db.hitobito.com
Reply-To: hans.muster@example.com
Return-Path: hans.muster@example.com
To: abo_name@db.hitobito.com
Subject: Besprechung vom 31.03.2021 - Einladung & Traktanden
...
```
