# encoding: utf-8

#  Copyright (c) 2012-2015 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::AddRequestMailer < ApplicationMailer

  CONTENT_ADD_REQUEST_PERSON = 'add_request_person'
  CONTENT_ADD_REQUEST_RESPONSIBLES = 'add_request_responsibles'

  def ask_person_to_add(request, request_body_label, requester_name, requester_group_roles)
    person = request.person
    content = CustomContent.get(CONTENT_ADD_REQUEST_PERSON)

    envelope = ask_person_to_add_envelope(person, request.requester, content)
    values = ask_person_to_add_values(person,
                                      requester_name,
                                      requester_group_roles,
                                      request_body_label)

    mail(envelope) do |format|
      format.html { render text: content.body_with_values(values) }
    end
  end

  def ask_responsibles(request, responsibles)
    Person.mailing_emails_for(responsibles)
  end

  def approved(person, body, requester, user)

  end

  def rejected(person, body, requester, user)

  end

  private
  def ask_person_to_add_envelope(person, requester, content)
    { to: person.email, 
      subject: content.subject,
      return_path: return_path(requester),
      sender: return_path(requester),
      reply_to: requester.email }
  end

  def ask_person_to_add_values(person, requester_name, requester_group_roles, request_body_label)
    {
      'recipient-name' => person.greeting_name,
      'requester-name' => requester_name,
      'requester-group-roles' => requester_group_roles,
      'request-body-label' => request_body_label,
      'show-person-url' => person_url(person)
     }
  end

end
