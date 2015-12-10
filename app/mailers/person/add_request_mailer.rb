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
    compose(CONTENT_ADD_REQUEST_PERSON, person,
            'recipient-name' => person.first_name,
            'requester-name' => requester_name,
            'requester-group-roles' => requester_group_roles,
            'request-body-label' => request_body_label,
            'show-person-url' => show_person_url(person.id))
  end

  def ask_responsibles(request, responsibles)
    Person.mailing_emails_for(responsibles)
  end

  def approved(person, body, requester, user)

  end

  def rejected(person, body, requester, user)

  end

end
