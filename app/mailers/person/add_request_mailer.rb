# encoding: utf-8

#  Copyright (c) 2012-2015 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::AddRequestMailer < ApplicationMailer

  CONTENT_ADD_REQUEST_PERSON = 'person_add_request_person'.freeze
  CONTENT_ADD_REQUEST_RESPONSIBLES = 'person_add_request_responsibles'.freeze
  CONTENT_ADD_REQUEST_APPROVED = 'person_add_request_approved'.freeze
  CONTENT_ADD_REQUEST_REJECTED = 'person_add_request_rejected'.freeze

  attr_reader :add_request

  delegate :body, :person, :requester, to: :add_request

  def ask_person_to_add(add_request)
    @add_request        = add_request
    @answer_request_url = link_to_request
    @recipient          = person
    compose(person, CONTENT_ADD_REQUEST_PERSON, requester)
  end

  def ask_responsibles(add_request, responsibles)
    @add_request        = add_request
    @answer_request_url = link_to_add_requests
    @recipients         = responsibles
    compose(responsibles, CONTENT_ADD_REQUEST_RESPONSIBLES, requester)
  end

  def approved(person, body, requester, user)
    @add_request = body.person_add_requests.build(person: person, requester: requester)
    @recipient   = requester
    @user        = user
    compose(requester, CONTENT_ADD_REQUEST_APPROVED, user)
  end

  def rejected(person, body, requester, user)
    @add_request = body.person_add_requests.build(person: person, requester: requester)
    @recipient   = requester
    @user        = user
    compose(requester, CONTENT_ADD_REQUEST_REJECTED, user)
  end

  private

  def compose(recipients, content_key, sender)
    values = values_for_placeholders(content_key)
    custom_content_mail(recipients, content_key, values, with_personal_sender(sender))
  end

  def placeholder_request_body
    link_to(add_request.body_label, body_url)
  end

  def placeholder_recipient_name
    @recipient.greeting_name
  end

  def placeholder_requester_name
    requester.full_name
  end

  def placeholder_requester_roles
    roles_as_string(add_request.requester_full_roles)
  end

  def placeholder_answer_request_url
    @answer_request_url
  end

  def placeholder_recipient_names
    @recipients.collect(&:greeting_name).join(', ')
  end

  def placeholder_person_name
    person.full_name
  end

  def placeholder_approver_name
    @user.full_name
  end

  def placeholder_rejecter_name
    @user.full_name
  end

  def placeholder_approver_roles
    roles_as_string(layer_full_roles(@user))
  end

  def placeholder_rejecter_roles
    roles_as_string(layer_full_roles(@user))
  end

  def roles_as_string(roles)
    roles.collect { |r| r.to_s(:long) }.join(', ')
  end

  def layer_full_roles(person)
    person.roles.includes(:group).select do |r|
      r.group.layer_group_id == add_request.person_layer.try(:id) &&
        (r.class.permissions & [:layer_and_below_full, :layer_full]).present?
    end
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
    else raise ArgumentError, "Unknown body type #{body.class}"
    end
  end

  def body_params
    { body_type: add_request.class.name.demodulize,
      body_id: add_request.body_id }
  end

end
