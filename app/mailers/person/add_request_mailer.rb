# encoding: utf-8

#  Copyright (c) 2012-2015 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::AddRequestMailer < ApplicationMailer

  CONTENT_ADD_REQUEST_PERSON = 'add_request_person'
  CONTENT_ADD_REQUEST_RESPONSIBLES = 'add_request_responsibles'

  def ask_person_to_add(request)
    content = CustomContent.get(CONTENT_ADD_REQUEST_PERSON)

    to = Person.mailing_emails_for(request.person)
    envelope = mail_envelope(to, request.requester, content)
    values = person_mail_values(request.person, request)

    compose(envelope, content, values)
  end

  def ask_responsibles(request, responsibles)
    content = CustomContent.get(CONTENT_ADD_REQUEST_RESPONSIBLES)

    to = Person.mailing_emails_for(responsibles)
    envelope = mail_envelope(to, request.requester, content)
    recipient_names = responsibles.collect(&:greeting_name).join(', ')
    values = responsible_mail_values(recipient_names,
                                     request,
                                     request.person,
                                     request.person_layer.id)

    compose(envelope, content, values)
  end

  def approved(person, body, requester, user)

  end

  def rejected(person, body, requester, user)

  end

  private

  def compose(envelope, content, values)
    mail(envelope) do |format|
      format.html { render text: content.body_with_values(values) }
    end
  end

  def requester_full_roles(request)
    request.requester_full_roles.collect { |r| r.to_s(:long) }.join(', ')
  end

  def mail_envelope(to, requester, content)
    { to: to,
      subject: content.subject,
      return_path: return_path(requester),
      sender: return_path(requester),
      reply_to: requester.email }
  end

  def person_mail_values(person, request)
    { 'recipient-name' => person.greeting_name,
      'requester-name' => request.requester.full_name,
      'requester-roles' => requester_full_roles(request),
      'request-body' => link_to(request.body_label, body_url(request.body)),
      'answer-request-url' => link_to_request(person, request.body) }
  end


  def responsible_mail_values(recipient_names, request, person, person_layer_id)
    { 'person-name' => person.full_name,
      'recipient-names' => recipient_names,
      'requester-name' => request.requester.full_name,
      'requester-roles' => requester_full_roles(request),
      'request-body' => link_to(request.body_label, body_url(request.body)),
      'answer-request-url' => link_to_add_requests(person_layer_id, person.id, request.body) }
  end

  def link_to(name, url)
    "<a href=\"#{url}\">#{name}</a>"
  end

  def link_to_add_requests(person_layer_id, person_id, body)
    params = body_params(body)
    params[:person_id] = person_id
    params[:group_id] = person_layer_id
    url = group_person_add_requests_url(params)
    link_to(t('.request_link'), url)
  end

  def link_to_request(person, body)
    url = requested_person_url(person, body)
    link_to(t('.request_link'), url)
  end

  def body_url(body)
    case body
    when Event
      group_event_url(group_id: body.groups.first.id, id: body.id)
    when Group
      group_url(id: body.id)
    when MailingList
      group_mailing_list_url(group_id: body.group_id, id: body.id)
    else
      fail(ArgumentError, "Unknown body type #{body.class}")
    end
  end

  def requested_person_url(person, body)
    person_url(person, body_params(body))
  end

  def body_params(body)
    { body_type: body_type(body),
      body_id: body.id }
  end

  def body_type(body)
    body.class.base_class.name
  end

end
