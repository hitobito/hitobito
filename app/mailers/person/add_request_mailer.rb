# encoding: utf-8

#  Copyright (c) 2012-2015 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::AddRequestMailer < ApplicationMailer

  CONTENT_ADD_REQUEST_PERSON = 'person_add_request_person'
  CONTENT_ADD_REQUEST_RESPONSIBLES = 'person_add_request_responsibles'
  CONTENT_ADD_REQUEST_APPROVED = 'person_add_request_approved'
  CONTENT_ADD_REQUEST_REJECTED = 'person_add_request_rejected'

  attr_reader :add_request

  delegate :body, :person, :requester, to: :add_request

  def ask_person_to_add(add_request)
    @add_request = add_request
    values = person_mail_values
    compose(person, CONTENT_ADD_REQUEST_PERSON, values, requester)
  end

  def ask_responsibles(add_request, responsibles)
    @add_request = add_request
    recipient_names = responsibles.collect(&:greeting_name).join(', ')
    values = responsible_mail_values(recipient_names)
    compose(responsibles, CONTENT_ADD_REQUEST_RESPONSIBLES, values, requester)
  end

  def approved(person, body, requester, user)
    @add_request = body.person_add_requests.build(person: person, requester: requester)
    values = approved_mail_values(user)
    compose(requester, CONTENT_ADD_REQUEST_APPROVED, values, user)
  end

  def rejected(person, body, requester, user)
    @add_request = body.person_add_requests.build(person: person, requester: requester)
    values = rejected_mail_values(user)
    compose(requester, CONTENT_ADD_REQUEST_REJECTED, values, user)
  end

  private

  def compose(recipients, content_key, values, sender)
    values['request-body'] = link_to(add_request.body_label, body_url)
    custom_content_mail(recipients, content_key, values, with_personal_sender(sender))
  end


  def person_mail_values
    { 'recipient-name' => person.greeting_name,
      'requester-name' => requester.full_name,
      'requester-roles' => requester_full_roles,
      'answer-request-url' => link_to_request }
  end

  def responsible_mail_values(recipient_names)
    { 'recipient-names' => recipient_names,
      'person-name' => person.full_name,
      'requester-name' => requester.full_name,
      'requester-roles' => requester_full_roles,
      'answer-request-url' => link_to_add_requests }
  end

  def approved_mail_values(user)
    { 'recipient-name' => requester.greeting_name,
      'person-name' => person.full_name,
      'approver-name' => user.full_name }
  end

  def rejected_mail_values(user)
    { 'recipient-name' => requester.greeting_name,
      'person-name' => person.full_name,
      'rejecter-name' => user.full_name }
  end

  def requester_full_roles
    add_request.requester_full_roles.collect { |r| r.to_s(:long) }.join(', ')
  end

  def link_to_add_requests
    params = body_params
    params[:person_id] = add_request.person_id
    params[:group_id] = add_request.person_layer.id
    url = group_person_add_requests_url(params)
    link_to(t('.request_link'), url)
  end

  def link_to_request
    url = person_url(person, body_params)
    link_to(t('.request_link'), url)
  end

  def body_url
    case body
    when Group then group_url(id: body.id)
    when Event then group_event_url(group_id: body.groups.first.id, id: body.id)
    when MailingList then group_mailing_list_url(group_id: body.group_id, id: body.id)
    else fail(ArgumentError, "Unknown body type #{body.class}")
    end
  end

  def body_params
    { body_type: add_request.class.name.demodulize,
      body_id: add_request.body_id }
  end

end
