# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

CustomContent.seed_once(:key,
  {key: PersonMailer::CONTENT_LOGIN,
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

  {key: 'views/devise/sessions/info',
   placeholders_required: nil,
   placeholders_optional: nil},
)

send_login_id = CustomContent.get(PersonMailer::CONTENT_LOGIN).id
participation_confirmation_id = CustomContent.get(Event::ParticipationMailer::CONTENT_CONFIRMATION).id
participation_approval_id = CustomContent.get(Event::ParticipationMailer::CONTENT_APPROVAL).id
temp_login_id = CustomContent.get(Event::RegisterMailer::CONTENT_REGISTER_LOGIN).id
login_form_id = CustomContent.get('views/devise/sessions/info').id

CustomContent::Translation.seed_once(:custom_content_id, :locale,

  {custom_content_id: send_login_id,
   locale: 'de',
   label: 'Login senden',
   subject: "Willkommen bei #{Settings.application.name}",
   body: "Hallo {recipient-name}<br/><br/>" \
         "Willkommen bei #{Settings.application.name}! Unter dem folgenden Link kannst du " \
         "dein Login Passwort setzen:<br/><br/>{login-url}<br/><br/>" \
         "Bis bald!<br/><br/>{sender-name}" },

  {custom_content_id: send_login_id,
   locale: 'fr',
   label: 'Envoyer le login',
   body: "Salut {recipient-name}<br/><br/>" \
         "Bonjour chez #{Settings.application.name}! Voici le link pour mettre ton mot de passe:" \
         "<br/><br/>{login-url}<br/><br/>" \
         "A bientôt!<br/><br/>{sender-name}"},

  {custom_content_id: send_login_id,
   locale: 'en',
   label: 'Send login'},

  {custom_content_id: send_login_id,
   locale: 'it',
   label: 'Inviare il login'},

  {custom_content_id: participation_confirmation_id,
   locale: 'de',
   label: 'Anlass: E-Mail Anmeldebestätigung',
   subject: 'Bestätigung der Anmeldung',
   body: "Hallo {recipient-name}<br/><br/>" \
         "Du hast dich für folgenden Anlass angemeldet:<br/><br/>" \
         "{event-details}<br/><br/>" \
         "Falls du ein Login hast, kannst du deine Anmeldung unter folgender Adresse einsehen " \
         "und eine Bestätigung ausdrucken:<br/><br/>{application-url}" },

  {custom_content_id: participation_confirmation_id,
   locale: 'fr',
   label: "Événement: E-Mail de confirmation de l'inscription"},

  {custom_content_id: participation_confirmation_id,
   locale: 'en',
   label: 'Event: Application confirmation email'},

  {custom_content_id: participation_confirmation_id,
   locale: 'it',
   label: "Evento: E-mail per l'affermazione della inscrizione"},

  {custom_content_id: participation_approval_id,
   locale: 'de',
   label: 'Anlass: E-Mail Freigabe der Anmeldung',
   subject: 'Freigabe einer Kursanmeldung',
   body: "Hallo {recipient-names}<br/><br/>" \
         "{participant-name} hat sich für den folgenden Kurs angemeldet:<br/><br/>" \
         "{event-details}<br/><br/>" \
         "Bitte bestätige oder verwerfe diese Anmeldung unter der folgenden Adresse:<br/><br/>" \
         "{application-url}" },

  {custom_content_id: participation_approval_id,
   locale: 'fr',
   label: "Événement: E-Mail pour la libération de l'inscription"},

  {custom_content_id: participation_approval_id,
   locale: 'en',
   label: 'Event: Email for participation approval'},

  {custom_content_id: participation_approval_id,
   locale: 'it',
   label: "Evento: E-mail per l'abilitazione della inscrizione"},

  {custom_content_id: temp_login_id,
   locale: 'de',
   label: 'Anlass: Temporäres Login senden',
   subject: 'Anmeldelink für Anlass',
   body: "Hallo {recipient-name}<br/><br/>" \
         "Hier kannst du dich für den Anlass {event-name} anmelden:<br/><br/>" \
         "{event-url}<br/><br/>" \
         "Wir freuen uns, dich wieder mit dabei zu haben." },

  {custom_content_id: temp_login_id,
   locale: 'fr',
   label: 'Événement: Envoyer un login temporaire'},

  {custom_content_id: temp_login_id,
   locale: 'en',
   label: 'Event: Send temporary login'},

  {custom_content_id: temp_login_id,
   locale: 'it',
   label: 'Evento: Inviare un login temporaneamente'},

  {custom_content_id: login_form_id,
   locale: 'de',
   label: 'Login Informationen'},

  {custom_content_id: login_form_id,
   locale: 'fr',
   label: 'Informations au login'},

  {custom_content_id: login_form_id,
   locale: 'en',
   label: 'Login Information'},

  {custom_content_id: login_form_id,
   locale: 'it',
   label: 'Informazioni al login'},

)
