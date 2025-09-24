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
    attribute :company_name, :string
    attribute :company, :boolean
    attribute :email, :string
    attribute :adult_consent, :boolean, readable: false
    attribute :privacy_policy_accepted, :boolean
  end

  before_attributes :check_adult_consent
  before_save :check_privacy_policy_accepted
  before_save :build_role

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
    policy_finder = Group::PrivacyPolicyFinder.for(group: group, person: model)
    return unless policy_finder.acceptance_needed?
    invalid_request!(:privacy_policy_accepted, :must_be_accepted) unless model.privacy_policy_accepted?
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
