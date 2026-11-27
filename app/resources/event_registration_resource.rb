# frozen_string_literal: true

#  Copyright (c) 2026, Berner Fachhochschule. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventRegistrationResource < ApplicationResource
  self.model = Event::ApiRegistration
  self.adapter = Graphiti::Adapters::Null
  self.type = :event_registrations
  # Graphiti does not support path parameters. Graphiti-openapi replaces the /1/ with a
  # path parameter in the API docs.
  primary_endpoint "events/1/registrations", [:create]

  PERSON_ATTRIBUTE_TYPES = {date: :date, boolean: :boolean, integer: :integer}.freeze

  attribute :id, :uuid, writable: false, filterable: false

  with_options readable: false, filterable: false, sortable: false do
    Event::ApiRegistration::Applicant.person_attributes.each do |attr|
      attribute attr, PERSON_ATTRIBUTE_TYPES.fetch(Person.type_for_attribute(attr).type, :string)
    end
    attribute :answers, :array
    attribute :privacy_policy_accepted, :boolean
    attribute :send_confirmation, :boolean
  end

  attribute :registration_status, :string, writable: false, filterable: false, sortable: false

  def build(model_class, _meta = nil)
    model_class.new(event: context.event)
  end

  def save(registration, _meta = nil)
    registration.save
    registration
  end

  def base_scope
    {}
  end

  def self.allow_request?(request_path, _params, action)
    return false unless action == :create

    route = ::Rails.application.routes.recognize_path(request_path, method: :post)
    route[:controller] == "json_api/event_registrations"
  end

  private

  def authorize_create(_model)
    authorize!(:register_participations, context.event)
  end
end
