# encoding: utf-8

#  Copyright (c) 2012-2015 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::AddRequestMailer < ApplicationMailer

  CONTENT_ADD_REQUEST_PERSON = 'add_request_person'
  CONTENT_ADD_REQUEST_RESPONSIBLES = 'add_request_responsibles'

  def ask_person_to_add(request)
    person = request.person
    content = CustomContent.get(CONTENT_ADD_REQUEST_PERSON)

    envelope = add_request_envelope(person.email, request.requester, content)
    values = ask_person_to_add_values(person, request)
    compose(content, envelope, values)
  end

  def ask_responsibles(request, responsibles, group)
    person = request.person
    content = CustomContent.get(CONTENT_ADD_REQUEST_RESPONSIBLES)

    to = Person.mailing_emails_for(responsibles)

    envelope = add_request_envelope(to, request.requester, content)

    recipient_names = responsibles.collect(&:greeting_name).join(', ')
    values = ask_responsibles_to_add_values(recipient_names,
                                            request,
                                            person,
                                            group.id)

    compose(content, envelope, values)
  end

  def approved(person, body, requester, user)

  end

  def rejected(person, body, requester, user)

  end

  private
  def compose(content, envelope, values)
    mail(envelope) do |format|
      format.html { render text: content.body_with_values(values) }
    end
  end

  def requester_group_roles(request)
    roles = request.requester.roles.includes(:group).select do |r|
      (r.class.permissions &
       [:layer_and_below_full, :layer_full, :group_and_below_full, :group_full]).present?
    end
    roles.collect { |r| r.to_s(:long) }.join(', ')
  end

  def add_request_envelope(to, requester, content)
    { to: to,
      subject: content.subject,
      return_path: return_path(requester),
      sender: return_path(requester),
      reply_to: requester.email }
  end

  def ask_person_to_add_values(person, request)
    {
      'recipient-name' => person.greeting_name,
      'requester-name' => request.requester.full_name,
      'requester-group-roles' => requester_group_roles(request),
      'request-body-label' => request.body_label,
      'show-person-url' => person_url(person)
    }
  end


  def ask_responsibles_to_add_values(recipient_names, request, person, group_id)
    {
      'person-name' => person.full_name,
      'recipient-names' => recipient_names,
      'requester-name' => request.requester.full_name,
      'requester-group-roles' => requester_group_roles(request),
      'request-body-label' => request.body_label,
      'add-requests-url' => group_person_add_requests_url(group_id: group_id)
    }
  end


end
