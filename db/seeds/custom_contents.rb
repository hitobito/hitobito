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
  { key: Person::SecurityToolsController::PASSWORD_COMPROMISED_SITUATION,
    placeholders_required: 'person-name',
    placeholders_optional: nil },
  { key: Person::SecurityToolsController::PASSWORD_COMPROMISED_SOLUTION,
    placeholders_required: 'person-name',
    placeholders_optional: nil },
  { key: Person::SecurityToolsController::EMAIL_COMPROMISED_SITUATION,
    placeholders_required: 'person-name',
    placeholders_optional: nil },
  { key: Person::SecurityToolsController::EMAIL_COMPROMISED_SOLUTION,
    placeholders_required: 'person-name',
    placeholders_optional: nil },
  { key: Person::SecurityToolsController::DATALEAK_SITUATION,
    placeholders_required: 'person-name',
    placeholders_optional: nil },
  { key: Person::SecurityToolsController::DATALEAK_SOLUTION,
    placeholders_required: 'person-name',
    placeholders_optional: nil },
  { key: Person::SecurityToolsController::SUSPEND_PERSON_SITUATION,
    placeholders_required: 'person-name',
    placeholders_optional: nil },
  { key: Person::SecurityToolsController::SUSPEND_PERSON_SOLUTION,
    placeholders_required: 'person-name',
    placeholders_optional: nil },
  { key: Event::ParticipationMailer::CONTENT_CONFIRMATION,
    placeholders_required: 'event-details, application-url',
    placeholders_optional: 'recipient-name' },
  { key: Event::ParticipationMailer::CONTENT_PENDING,
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
  { key: Person::UserPasswordOverrideMailer::CONTENT_USER_PASSWORD_OVERRIDE,
    placeholders_required: 'taker-name, recipient-name',
    placeholders_optional: nil },
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
    placeholders_optional: nil },
  { key: Groups::SelfRegistrationNotificationMailer::CONTENT_SELF_REGISTRATION_NOTIFICATION,
    placeholders_required: 'person-name, group-name, person-url',
    placeholders_optional: nil }
)

send_login_id = CustomContent.get(Person::LoginMailer::CONTENT_LOGIN).id
password_compromised_situation_id = CustomContent.get(Person::SecurityToolsController::PASSWORD_COMPROMISED_SITUATION).id
password_compromised_solution_id = CustomContent.get(Person::SecurityToolsController::PASSWORD_COMPROMISED_SOLUTION).id
email_compromised_situation_id = CustomContent.get(Person::SecurityToolsController::EMAIL_COMPROMISED_SITUATION).id
email_compromised_solution_id = CustomContent.get(Person::SecurityToolsController::EMAIL_COMPROMISED_SOLUTION).id
dataleak_situation_id = CustomContent.get(Person::SecurityToolsController::DATALEAK_SITUATION).id
dataleak_solution_id = CustomContent.get(Person::SecurityToolsController::DATALEAK_SOLUTION).id
suspend_person_situation_id = CustomContent.get(Person::SecurityToolsController::SUSPEND_PERSON_SITUATION).id
suspend_person_solution_id = CustomContent.get(Person::SecurityToolsController::SUSPEND_PERSON_SOLUTION).id
participation_confirmation_id = CustomContent.get(Event::ParticipationMailer::CONTENT_CONFIRMATION).id
participation_pending_id = CustomContent.get(Event::ParticipationMailer::CONTENT_PENDING).id
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
user_password_override_id = CustomContent.get(Person::UserPasswordOverrideMailer::CONTENT_USER_PASSWORD_OVERRIDE).id
bulk_mail_success_id = CustomContent.get(DeliveryReportMailer::CONTENT_BULK_MAIL_SUCCESS).id
bulk_mail_with_failed_id = CustomContent.get(DeliveryReportMailer::CONTENT_BULK_MAIL_WITH_FAILED).id
address_validation_checks_id = CustomContent.get(Address::ValidationChecksMailer::CONTENT_ADDRESS_VALIDATION_CHECKS).id
assignment_assignee_notification_id = CustomContent.get(Assignment::AssigneeNotificationMailer::CONTENT_ASSIGNMENT_ASSIGNEE_NOTIFICATION).id
self_registration_notification_id = CustomContent.get(Groups::SelfRegistrationNotificationMailer::CONTENT_SELF_REGISTRATION_NOTIFICATION).id

CustomContent::Translation.seed_once(:custom_content_id, :locale,

  {custom_content_id: self_registration_notification_id,
   locale: 'de',
   label: 'Benachrichtigung Selbstregistrierung',
   subject: 'Benachrichtigung Selbstregistrierung',
   body: "Die Person {person-name} hat sich auf der Gruppe {group-name} per Selbstregistrierung angemeldet:<br/><br/>{person-url}" },

  {custom_content_id: self_registration_notification_id,
   locale: 'en',
   label: 'Self Registration Notification' },

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

  {custom_content_id: password_compromised_situation_id,
   locale: 'de',
   label: 'Passwort nicht sicher',
   subject: 'Sicherheitsübersicht: Account wurde übernommen?',
   body: "Vermutest du, dass jemand den Account von {person-name} übernommen hat? Oder ist das Passwort nicht mehr sicher?"},

  {custom_content_id: password_compromised_situation_id,
   locale: 'fr',
   label: 'Mot de passe non sécurisé'},

  {custom_content_id: password_compromised_situation_id,
   locale: 'it',
   label: 'Password non sicura'},

  {custom_content_id: password_compromised_situation_id,
   locale: 'en',
   label: 'Password not secure'},

  {custom_content_id: password_compromised_solution_id,
   locale: 'de',
   label: 'Passwort absichern',
   subject: 'Sichheitsübersicht: Lösung zu Account wurde übernommen',
   body: "Bitte überschreibe das Passwort mit dem folgenden Button. {person-name} kann sich ein neues Passwort über die Funktion \"Passwort zurücksetzen\" zusenden lassen." },

  {custom_content_id: password_compromised_solution_id,
   locale: 'fr',
   label: 'Sécuriser le mot de passe'},

  {custom_content_id: password_compromised_solution_id,
   locale: 'it',
   label: 'Password sicura'},

  {custom_content_id: password_compromised_solution_id,
   locale: 'en',
   label: 'Secure the password'},

  {custom_content_id: email_compromised_situation_id,
   locale: 'de',
   label: 'E-Mail-Adresse nicht sicher',
   subject: 'Sicherheitsübersicht: E-Mail-Adresse wurde übernommen?',
   body: "Vermutest du, dass jemand die Kontrolle über die E-Mail-Adresse von {person-name} unerlaubt übernommen hat?"},

  {custom_content_id: email_compromised_situation_id,
   locale: 'fr',
   label: 'Adresse e-mail non sécurisée'},

  {custom_content_id: email_compromised_situation_id,
   locale: 'it',
   label: 'Indirizzo e-mail non sicuro'},

  {custom_content_id: email_compromised_situation_id,
   locale: 'en',
   label: 'E-mail address not secure'},

  {custom_content_id: email_compromised_solution_id,
   locale: 'de',
   label: 'Login über E-Mail verhindern',
   subject: 'Sichheitsübersicht: Lösung zu E-Mail-Adresse wurde übernommen',
   body: "Bitte lösche die Haupt-E-Mail von {person-name} und kläre die Situation ab. Wenn du sicher bist, dass keine unbefugte Person auf diesen Account zugreifen kann, kannst du die Haupt-E-Mail wieder eintragen. Du kannst die Haupt-E-Mail auch temporär als Weitere E-Mail abspeichern, damit du sie später wieder findest." },

  {custom_content_id: email_compromised_solution_id,
   locale: 'fr',
   label: 'Empêcher la connexion par e-mail'},

  {custom_content_id: email_compromised_solution_id,
   locale: 'it',
   label: 'Impedire il login via e-mail'},

  {custom_content_id: email_compromised_solution_id,
   locale: 'en',
   label: 'Prevent login via e-mail'},

  {custom_content_id: dataleak_situation_id,
   locale: 'de',
   label: 'Daten geleaked',
   subject: 'Sicherheitsübersicht: Daten geleaked?',
   body: "Gab es einen Datenmissbrauch oder hat {person-name} unerlaubt Daten weitergegeben?"},

  {custom_content_id: dataleak_situation_id,
   locale: 'fr',
   label: 'Fuite de données'},

  {custom_content_id: dataleak_situation_id,
   locale: 'it',
   label: 'Dati trapelati'},

  {custom_content_id: dataleak_situation_id,
   locale: 'en',
   label: 'Data leaked'},

  {custom_content_id: dataleak_solution_id,
   locale: 'de',
   label: 'Alle Rollen entfernen',
   subject: 'Sichheitsübersicht: Lösung zu Datenmissbrauch',
   body: "Dann solltest du {person-name} temporär alle Rollen in deiner Gruppe entfernen." },

  {custom_content_id: dataleak_solution_id,
   locale: 'fr',
   label: 'Retirer tous les rôles'},

  {custom_content_id: dataleak_solution_id,
   locale: 'it',
   label: 'Rimuovere tutti i ruoli'},

  {custom_content_id: dataleak_solution_id,
   locale: 'en',
   label: 'Remove all rolls'},

  {custom_content_id: suspend_person_situation_id,
   locale: 'de',
   label: 'Person ausschliessen',
   subject: 'Sicherheitsübersicht: Person ausschliessen?',
   body: "Möchtest du {person-name} ganz aus Hitobito ausschliessen?"},

  {custom_content_id: suspend_person_situation_id,
   locale: 'fr',
   label: 'Exclure la personne'},

  {custom_content_id: suspend_person_situation_id,
   locale: 'it',
   label: 'Escludere la persona'},

  {custom_content_id: suspend_person_situation_id,
   locale: 'en',
   label: 'Exclude person'},

  {custom_content_id: suspend_person_solution_id,
   locale: 'de',
   label: 'Haupt-E-Mail löschen',
   subject: 'Sicherheitsübersicht: Lösung bei Person ausschliessen',
   body: "Dafür kannst du die Haupt-E-Mail von {person-name} löschen. Bitte informiere weitere zuständige Personen von diesem Vorfall. Besonders wenn {person-name} noch weitere Rollen ausserhalb deiner Ebene hat." },

  {custom_content_id: suspend_person_solution_id,
   locale: 'fr',
   label: 'Supprimer l\'e-mail principal'},

  {custom_content_id: suspend_person_solution_id,
   locale: 'it',
   label: 'Cancellare l\'e-mail principale'},

  {custom_content_id: suspend_person_solution_id,
   locale: 'en',
   label: 'Delete main email'},

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

  {custom_content_id: participation_pending_id,
   locale: 'de',
   label: 'Anlass: E-Mail Voranmeldung',
   subject: 'Voranmeldung eingegangen',
   body: "Hallo {recipient-name}<br/><br/>" \
         "Wir haben deine Vornameldung für die Teilnahme an folgendem Anlass erhalten:<br/><br/>" \
         "{event-details}<br/><br/>" \
         "Deine Anmeldung ist noch nicht definitiv und muss erst noch bestätigt werden.<br/><br/>" \
         "Falls du ein Login hast, kannst du deine Anmeldung unter folgender Adresse einsehen:<br/><br/>{application-url}" },

  {custom_content_id: participation_pending_id,
   locale: 'fr',
   label: "Événement: Préinscription par E-Mail"},

  {custom_content_id: participation_pending_id,
   locale: 'en',
   label: 'Event: Pre registration email'},

  {custom_content_id: participation_pending_id,
   locale: 'it',
   label: "Evento: E-mail pre-registrazione"},

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

  {custom_content_id: user_password_override_id,
   locale: 'de',
   label: 'Login verhindert',
   subject: "Login für [#{Settings.application.name}] von {taker-name} verhindert",
   body: "Hallo {recipient-name}, <br/>" \
   "{taker-name} hat auf [#{Settings.application.name}] das Passwort deines Accounts zurückgesetzt. " \
   "Dies geschieht typischerweise, wenn jemand den Verdacht hat, dass dein Passwort nicht mehr sicher ist. <br/>" \
   "Im Moment kann sich also niemand mit deinem Account einloggen. Du kannst über die Funktion \"Passwort vergessen\" "\
   "ein neues Passwort anfordern"},

  {custom_content_id: user_password_override_id,
   locale: 'fr',
   label: 'Connexion empêchée'},

  {custom_content_id: user_password_override_id,
   locale: 'it',
   label: 'Accesso impedito'},

  {custom_content_id: user_password_override_id,
   locale: 'en',
   label: 'Login prevented'},

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
