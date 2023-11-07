# frozen_string_literal: true
#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Groups::SelfRegistration
  include TransientModel

  attr_accessor :group, :person_attributes, :step, :single

  class_attribute :steps, default: [Groups::SelfRegistrations::PersonComponent]

  def initialize(group:, params:)
    @group = group
    @step = (params || {})[:step].to_i
    @person_attributes = extract_attrs(params, :person_attributes)
  end

  def save
    Person.transaction do
      person_model = create_person
      create_role(person_model)
    end
    true
  rescue
    false
  end

  def set_privacy_policy_acceptance(value)
    person.privacy_policy_accepted = value
  end

  def valid?
    person.valid?
  end

  def person
    @person ||= build_person(@person_attributes)
  end

  def person_email
    person.email
  end

  def increment_step
    @step += 1
  end

  def last_step?
    @step == (steps.size - 1)
  end

  def first_step?
    @step.zero?
  end

  def self.base_class
    Groups::SelfRegistration
  end

  private

  def build_person(attrs, model_class = Person)
    model_class.new(attrs.merge(primary_group_id: group.id))
  end

  def create_person
    person.save!
    person
  end

  def create_role(person)
    Role.create!(
      group: @group,
      type: @group.self_registration_role_type,
      person: person
    )
  end

  def extract_attrs(params, key, permitted_attrs: PeopleController.permitted_attrs, array: false)
    return {} if params.nil?

    params = params.require(key).permit(*permitted_attrs)
    array ? params.values : params
  end

end
