# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

CustomContent.seed_once(:key,
  {key: 'send_login',
   placeholders_required: 'login-url',
   placeholders_optional: 'recipient-name, sender-name'},

  {key: Event::ParticipationMailer::CONTENT_CONFIRMATION,
   placeholders_required: 'event-details, application-url',
   placeholders_optional: 'recipient-name'},

  {key: Event::ParticipationMailer::CONTENT_APPROVAL,
   placeholders_required: 'participant-name, event-details, application-url',
   placeholders_optional: 'recipient-names'},

  {key: Event::RegisterMailer::CONTENT_REGISTER_LOGIN,
   placeholders_required: 'event-url',
   placeholders_optional: 'recipient-name, event-name'},
)

CustomContent::Translation.seed_once(:custom_content_id, :locale,
  {custom_content_id: CustomContent.where(key: 'send_login').first.id,
   locale: 'de',
   label: 'Login senden',
   subject: "Willkommen bei #{Settings.application.name}",
   body: "Hallo {recipient-name}<br/><br/>Willkommen bei #{Settings.application.name}! Unter dem folgenden Link kannst du dein Login Passwort setzen:<br/><br/>{login-url}<br/><br/>Bis bald!<br/><br/>{sender-name}" },

  {custom_content_id: CustomContent.where(key: Event::ParticipationMailer::CONTENT_CONFIRMATION).first.id,
   locale: 'de',
   label: 'Anlass: E-Mail Anmeldebestätigung',
   subject: 'Bestätigung der Anmeldung',
   body: "Hallo {recipient-name}<br/><br/>Du hast dich für folgenden Anlass angemeldet:<br/><br/>{event-details}<br/><br/>Falls du ein Login hast, kannst du deine Anmeldung unter folgender Adresse einsehen und eine Bestätigung ausdrucken:<br/><br/>{application-url}" },

  {custom_content_id: CustomContent.where(key: Event::ParticipationMailer::CONTENT_APPROVAL).first.id,
   locale: 'de',
   label: 'Anlass: E-Mail Freigabe der Anmeldung',
   subject: 'Freigabe einer Kursanmeldung',
   body: "Hallo {recipient-names}<br/><br/>{participant-name} hat sich für den folgenden Kurs angemeldet:<br/><br/>{event-details}<br/><br/>Bitte bestätige oder verwerfe diese Anmeldung unter der folgenden Adresse:<br/><br/>{application-url}" },

  {custom_content_id: CustomContent.where(key: Event::RegisterMailer::CONTENT_REGISTER_LOGIN).first.id,
   locale: 'de',
   label: 'Anlass: Temporäres Login senden',
   subject: 'Anmeldelink für Anlass',
   body: "Hallo {recipient-name}<br/><br/>Hier kannst du dich für den Anlass {event-name} anmelden:<br/><br/>{event-url}<br/><br/>Wir freuen uns, dich wieder mit dabei zu haben." }
)
