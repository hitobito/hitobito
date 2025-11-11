# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SelfRegistrationResource < ApplicationResource
  self.model = ::Person
  # For graphiti to find the controller associated with this resource, we have to set a specific
  # value for the group id in the path here. Graphiti-openapi will recognize the /1/ and replace
  # it with an actual variable parameter in the API docs.
  # This is necessary because graphiti by default does not allow path parameters at all.
  primary_endpoint "groups/1/self_registrations", [:create]

  with_options filterable: false, sortable: false do
    attribute :first_name, :string
    attribute :last_name, :string
    attribute :nickname, :string
    attribute :company_name, :string if FeatureGate.enabled? :self_registration_company
    attribute :company, :boolean if FeatureGate.enabled? :self_registration_company
    attribute :email, :string
    attribute :adult_consent, :boolean, readable: false
    attribute :privacy_policy_accepted, :boolean
  end

  before_attributes :check_adult_consent
  before_save :check_privacy_policy_accepted
  before_save :build_role
  after_save :enqueue_duplicate_locator_job
  after_save :enqueue_notification_email
  after_save :send_password_reset_email

  def base_scope
    Person.none
  end

  def self.allow_request?(request_path, params, action)
    # Due to the graphiti manipulations above, we have to implement this method ourselves.
    # This is an intended feature of graphiti, it's fine to override this method.
    return false unless action == :create
    route = ::Rails.application.routes.recognize_path(request_path, method: :post)
    route[:controller] == "json_api/self_registrations"
  end

  private

  def authorize_create(model)
    current_ability.authorize!(:register_people, group)
  end

  def check_adult_consent(attributes)
    consent_given = attributes.delete(:adult_consent)
    return unless group.self_registration_require_adult_consent?
    invalid_request!(:adult_consent, :must_be_accepted) unless consent_given
  end

  def check_privacy_policy_accepted(model)
    return if model.privacy_policy_accepted?
    policy_finder = Group::PrivacyPolicyFinder.for(group: group, person: model)
    return unless policy_finder.acceptance_needed?
    validation_error!(model, :privacy_policy_accepted, :must_be_accepted)
  end

  def enqueue_duplicate_locator_job(model)
    Person::DuplicateLocatorJob.new(model.id).enqueue!
  end

  def enqueue_notification_email(model)
    return if group.self_registration_notification_email.blank?

    Groups::SelfRegistrationNotificationMailer
      .self_registration_notification(group.self_registration_notification_email, model.roles.first)
      .deliver_later
  end

  def send_password_reset_email(model)
    return if model.email.blank?

    Person.send_reset_password_instructions(email: model.email)
  end

  def build_role(model)
    model.roles.build(group_id: group.id, type: role_type)
  end

  def role_type
    group.self_registration_role_type
  end

  def group
    context.group
  end
end
