# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

CustomContent.seed_once(
  :key,
  { key: Person::LoginMailer::CONTENT_LOGIN,
    placeholders_required: 'login-url',
    placeholders_optional: 'recipient-name, sender-name' },
  { key: Event::ParticipationMailer::CONTENT_CONFIRMATION,
    placeholders_required: 'event-details, application-url',
    placeholders_optional: 'recipient-name' },
  { key: Event::ParticipationMailer::CONTENT_NOTIFICATION,
    placeholders_required: 'event-name, participant-name',
    placeholders_optional: 'application-url, participation-details' },
  { key: Event::ParticipationMailer::CONTENT_APPROVAL,
    placeholders_required: 'participant-name, event-details, application-url',
    placeholders_optional: 'recipient-names' },
  { key: Event::ParticipationMailer::CONTENT_CANCEL,
    placeholders_required: 'event-details',
    placeholders_optional: 'recipient-name' },
  { key: Event::RegisterMailer::CONTENT_REGISTER_LOGIN,
    placeholders_required: 'event-url',
    placeholders_optional: 'recipient-name, event-name' },
  { key: 'views/devise/sessions/info',
    placeholders_required: nil,
    placeholders_optional: nil },
  { key: Person::AddRequestMailer::CONTENT_ADD_REQUEST_PERSON,
    placeholders_required: 'request-body, answer-request-url',
    placeholders_optional: 'recipient-name, requester-name, requester-roles' },
  { key: Person::AddRequestMailer::CONTENT_ADD_REQUEST_RESPONSIBLES,
    placeholders_required: 'person-name, request-body, answer-request-url',
    placeholders_optional: 'recipient-names, requester-name, requester-roles' },
  { key: Person::AddRequestMailer::CONTENT_ADD_REQUEST_APPROVED,
    placeholders_required: 'person-name, request-body',
    placeholders_optional: 'recipient-name, approver-name, approver-roles' },
  { key: Person::AddRequestMailer::CONTENT_ADD_REQUEST_REJECTED,
    placeholders_required: 'person-name, request-body',
    placeholders_optional: 'recipient-name, rejecter-name, rejecter-roles' },
  { key: InvoiceMailer::CONTENT_INVOICE_NOTIFICATION,
    placeholders_required: '',
    placeholders_optional: 'recipient-name, group-name, group-address, invoice-number, invoice-items, invoice-total, payment-information' },
  { key: Person::UserImpersonationMailer::CONTENT_USER_IMPERSONATION,
    placeholders_required: 'taker-name',
    placeholders_optional: 'recipient-name' },
  { key: DeliveryReportMailer::CONTENT_BULK_MAIL_SUCCESS,
    placeholders_required: 'mail-subject, delivered-at, mail-to, total-recipients',
    placeholders_optional: nil },
  { key: DeliveryReportMailer::CONTENT_BULK_MAIL_WITH_FAILED,
    placeholders_required: 'mail-subject, delivered-at, mail-to, total-recipients, total-succeeded-recipients, failed-recipients',
    placeholders_optional: nil },
  { key: Address::ValidationChecksMailer::CONTENT_ADDRESS_VALIDATION_CHECKS,
    placeholders_required: 'invalid-people',
    placeholders_optional: nil },
  { key: Assignment::AssigneeNotificationMailer::CONTENT_ASSIGNMENT_ASSIGNEE_NOTIFICATION,
    placeholders_required: 'assignment-title',
    placeholders_optional: nil }
)

send_login_id = CustomContent.get(Person::LoginMailer::CONTENT_LOGIN).id
participation_confirmation_id = CustomContent.get(Event::ParticipationMailer::CONTENT_CONFIRMATION).id
participation_notification_id = CustomContent.get(Event::ParticipationMailer::CONTENT_NOTIFICATION).id
participation_approval_id = CustomContent.get(Event::ParticipationMailer::CONTENT_APPROVAL).id
cancel_application_id = CustomContent.get(Event::ParticipationMailer::CONTENT_CANCEL).id
temp_login_id = CustomContent.get(Event::RegisterMailer::CONTENT_REGISTER_LOGIN).id
login_form_id = CustomContent.get('views/devise/sessions/info').id
add_request_person_id = CustomContent.get(Person::AddRequestMailer::CONTENT_ADD_REQUEST_PERSON).id
add_request_responsibles_id = CustomContent.get(Person::AddRequestMailer::CONTENT_ADD_REQUEST_RESPONSIBLES).id
add_request_approved_id = CustomContent.get(Person::AddRequestMailer::CONTENT_ADD_REQUEST_APPROVED).id
add_request_rejected_id = CustomContent.get(Person::AddRequestMailer::CONTENT_ADD_REQUEST_REJECTED).id
invoice_notification_id = CustomContent.get(InvoiceMailer::CONTENT_INVOICE_NOTIFICATION).id
user_impersonation_id = CustomContent.get(Person::UserImpersonationMailer::CONTENT_USER_IMPERSONATION).id
bulk_mail_success_id = CustomContent.get(DeliveryReportMailer::CONTENT_BULK_MAIL_SUCCESS).id
bulk_mail_with_failed_id = CustomContent.get(DeliveryReportMailer::CONTENT_BULK_MAIL_WITH_FAILED).id
address_validation_checks_id = CustomContent.get(Address::ValidationChecksMailer::CONTENT_ADDRESS_VALIDATION_CHECKS).id
assignment_assignee_notification_id = CustomContent.get(Assignment::AssigneeNotificationMailer::CONTENT_ASSIGNMENT_ASSIGNEE_NOTIFICATION).id

CustomContent::Translation.seed_once(:custom_content_id, :locale,

  {custom_content_id: assignment_assignee_notification_id,
   locale: 'de',
   label: 'Auftrag erhalten',
   subject: 'Druckauftrag erhalten',
   body: "Sie haben einen neuen Druckauftrag: {assignment-title} erhalten. Login Sie sich bitte ein, um diesen einzusehen." },

  {custom_content_id: address_validation_checks_id,
   locale: 'de',
   label: 'Addressen Validations Checks',
   subject: 'Address Validierungen',
   body: "Die Personen: {invalid-people} haben Addressen, welche nicht im Archiv gefunden wurden." },

  {custom_content_id: address_validation_checks_id,
   locale: 'fr',
   label: 'Addressen Validations Checks',
   subject: 'Validation des adresses',
   body: "Les personnes: {invalid-people} ont des adresses, qui n'ont pas été trouvées dans les archives." },

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

  {custom_content_id: participation_notification_id,
   locale: 'de',
   label: 'Anlass: E-Mail Teilnehmer-/in hat sich angemeldet',
   subject: 'Anlass: Teilnehmer-/in hat sich angemeldet',
   body: 'Hallo<br><br>' \
         '{participant-name} hat sich für den Anlass "{event-name}" angemeldet:<br><br>' \
         '{application-url}<br>' },

  {custom_content_id: participation_notification_id,
   locale: 'fr',
   label: 'Événement: E-Mail Participant/-e a enregistré' },

  {custom_content_id: participation_notification_id,
   locale: 'en',
   label: 'Event: E-Mail Participant has applied' },

  {custom_content_id: participation_notification_id,
   locale: 'it',
   label: 'Evento: E-Mail Participante ha registrato'},

  {custom_content_id: cancel_application_id,
   locale: 'de',
   label: 'Anlass: E-Mail Abmeldebestätigung',
   subject: 'Bestätigung der Abmeldung',
   body: "Hallo {recipient-name}<br/><br/>" \
         "Du hast dich von folgendem Anlass abgemeldet:<br/><br/>" \
         "{event-details}<br/><br/>"},

  {custom_content_id: cancel_application_id,
   locale: 'fr',
   label: "Événement: E-Mail de confirmation de la désinscription"},

  {custom_content_id: cancel_application_id,
   locale: 'en',
   label: 'Event: Deregistration confirmation email'},

  {custom_content_id: cancel_application_id,
   locale: 'it',
   label: "Evento: E-mail per l'affermazione della disinscrizione"},

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
   label: "Événement: E-Mail pour débloquer l'inscription"},

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
   label: 'Informations sur le login'},

  {custom_content_id: login_form_id,
   locale: 'en',
   label: 'Login Information'},

  {custom_content_id: login_form_id,
   locale: 'it',
   label: 'Informazioni al login'},

  {custom_content_id: add_request_person_id,
   locale: 'de',
   label: 'Anfrage Personendaten: E-Mail Freigabe durch Person',
   subject: 'Freigabe deiner Personendaten',
   body: "Hallo {recipient-name}<br/><br/>" \
         "{requester-name} möchte dich hier hinzufügen: <br/><br/>" \
         "{request-body}<br/><br/>" \
         "{requester-name} hat folgende schreibberechtigten Rollen: <br/><br/>" \
         "{requester-roles}<br/><br/>" \
         "Bitte bestätige oder verwerfe diese Anfrage:<br/><br/>" \
         "{answer-request-url}" },

  {custom_content_id: add_request_person_id,
   locale: 'fr',
   label: 'Demande sur les données personnelles: Email pour la libération par la personne'},

  {custom_content_id: add_request_person_id,
   locale: 'en',
   label: 'Personal data request: E-mail approval by person'},

  {custom_content_id: add_request_person_id,
   locale: 'it',
   label: "Richiesta dei dati personali: E-mail per l'abilitazione per mano della persona"},

  {custom_content_id: add_request_responsibles_id,
   locale: 'de',
   label: 'Anfrage Personendaten: E-Mail Freigabe durch Verantwortliche',
   subject: 'Freigabe Personendaten',
   body: "Hallo {recipient-names}<br/><br/>" \
         "{requester-name} möchte {person-name} hier hinzufügen: <br/><br/>" \
         "{request-body}<br/><br/>" \
         "{requester-name} hat folgende schreibberechtigten Rollen: <br/><br/>" \
         "{requester-roles}<br/><br/>" \
         "Bitte bestätige oder verwerfe diese Anfrage:<br/><br/>" \
         "{answer-request-url}" },

  {custom_content_id: add_request_responsibles_id,
   locale: 'fr',
   label: 'Demande sur les données personnelles: E-mail pour la libération par les responsables'},

  {custom_content_id: add_request_responsibles_id,
   locale: 'en',
   label: 'Personal data request: Email approval by responsibles'},

  {custom_content_id: add_request_responsibles_id,
   locale: 'it',
   label: "Richiesta dei dati personali: E-mail per l'abilitazione per mano dei responsabili"},

  {custom_content_id: add_request_approved_id,
   locale: 'de',
   label: 'Anfrage Personendaten: E-Mail Freigabe akzeptiert',
   subject: 'Freigabe der Personendaten akzeptiert',
   body: "Hallo {recipient-name}<br/><br/>" \
         "{approver-name} hat deine Anfrage für {person-name} freigegeben.<br/><br/>" \
         "{person-name} wurde zu {request-body} hinzugefügt.<br/><br/>" \
         "{approver-name} hat folgende schreibberechtigten Rollen: <br/><br/>" \
         "{approver-roles}<br/><br/>" },

  {custom_content_id: add_request_approved_id,
   locale: 'fr',
   label: 'Demande sur les données personnelles: E-mail libération accepté'},

  {custom_content_id: add_request_approved_id,
   locale: 'en',
   label: 'Personal data request: Email approval accepted'},

  {custom_content_id: add_request_approved_id,
   locale: 'it',
   label: "Richiesta dei dati personali: Email abilitazione accettata"},

  {custom_content_id: add_request_rejected_id,
   locale: 'de',
   label: 'Anfrage Personendaten: E-Mail Freigabe abgelehnt',
   subject: 'Freigabe der Personendaten abgelehnt',
   body: "Hallo {recipient-name}<br/><br/>" \
         "{rejecter-name} hat deine Anfrage für {person-name} abgelehnt.<br/><br/>" \
         "{person-name} wird nicht zu {request-body} hinzugefügt.<br/><br/>" \
         "{rejecter-name} hat folgende schreibberechtigten Rollen: <br/><br/>" \
         "{rejecter-roles}<br/><br/>" },

  {custom_content_id: add_request_rejected_id,
   locale: 'fr',
   label: 'Demande sur les données personnelles: E-mail libre-accès refusé'},

  {custom_content_id: add_request_rejected_id,
   locale: 'en',
   label: 'Personal data request: Email approval rejected'},

  {custom_content_id: add_request_rejected_id,
   locale: 'it',
   label: "Richiesta dei dati personali: Email abilitazione rifiutata"},

  {custom_content_id: invoice_notification_id,
   locale: 'de',
   label: 'Rechnung',
   subject: 'Rechnung {invoice-number} von {group-name}',
   body: "<p>Hallo {recipient-name}</p>" \
   "<p>Rechnung von:</p>" \
   "<p><b>Absender: {group-address}</b></p>" \
   "<br/><br/>" \
   "{invoice-items}<br/><br/>" \
   "{invoice-total}<br/><br/>" \
   "{payment-information}<br/><br/>" },

  {custom_content_id: invoice_notification_id,
   locale: 'en',
   label: 'Rechnung' },

  {custom_content_id: invoice_notification_id,
   locale: 'fr',
   label: 'Rechnung' },

  {custom_content_id: invoice_notification_id,
   locale: 'it',
   label: 'Rechnung' },

  {custom_content_id: user_impersonation_id,
   locale: 'de',
   label: 'Benutzer impersonierung',
   subject: "Dein Account auf [#{Settings.application.name}] wurde von {taker-name} übernommen",
   body: "<p>Hallo {recipient-name}</p>" \
   "<p>{taker-name} hat auf [#{Settings.application.name}] deinen Account übernommen.</p>" \
   "<p>Falls du glaubst, dass dieser Zugriff von {taker-name} missbräuchlich ist, "\
   "melde dich beim Verantwortlichen der Datenbank."},

  {custom_content_id: user_impersonation_id,
   locale: 'en',
   label: 'Benutzer impersonierung' },

  {custom_content_id: user_impersonation_id,
   locale: 'fr',
   label: 'Benutzer impersonierung' },

  {custom_content_id: user_impersonation_id,
   locale: 'it',
   label: 'Benutzer impersonierung' },

  {custom_content_id: bulk_mail_success_id,
   locale: 'de',
   label: 'Sendebericht Abo',
   subject: 'Sendebericht Mail an {mail-to}',
   body: "Deine Mail an {mail-to} wurde verschickt:<br/><br/>" \
         "Betreff: {mail-subject}<br/>" \
         "Zeit: {delivered-at}<br/>" \
         "Empfänger: {total-recipients}<br/><br/>" },

  {custom_content_id: bulk_mail_success_id,
   locale: 'en',
   label: 'Sendebericht Abo' },

  {custom_content_id: bulk_mail_success_id,
   locale: 'fr',
   label: 'Sendebericht Abo' },

  {custom_content_id: bulk_mail_success_id,
   locale: 'it',
   label: 'Sendebericht Abo' },

  {custom_content_id: bulk_mail_with_failed_id,
   locale: 'de',
   label: 'Sendebericht Abo nicht alle erfolgreich',
   subject: 'Sendebericht Mail an {mail-to}',
   body: "Deine Mail an {mail-to} wurde verschickt:<br/><br/>" \
         "Betreff: {mail-subject}<br/>" \
         "Zeit: {delivered-at}<br/>" \
         "Empfänger: {total-succeeded-recipients}/{total-recipients}<br/><br/>" \
         "Folgende Empfänger konnten nicht zugestellt werden:<br/><br/>" \
         "{failed-recipients}<br/><br/>"},

  {custom_content_id: bulk_mail_with_failed_id,
   locale: 'en',
   label: 'Sendebericht Abo nicht alle erfolgreich' },

  {custom_content_id: bulk_mail_with_failed_id,
   locale: 'fr',
   label: 'Sendebericht Abo nicht alle erfolgreich' },

  {custom_content_id: bulk_mail_with_failed_id,
   locale: 'it',
   label: 'Sendebericht Abo nicht alle erfolgreich' },
)
