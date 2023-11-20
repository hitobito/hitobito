# frozen_string_literal: true
#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Groups::SelfRegistration
  include TransientModel

  attr_accessor :group, :person, :person_attributes, :step, :single

  class_attribute :steps, default: [Groups::SelfRegistrations::PersonComponent]

  def initialize(group:, params:)
    @group = group
    @step = (params || {})[:step].to_i
    @person_attributes = extract_attrs(params, :person_attributes)
  end

  def save!
    raise ActiveRecord::RecordInvalid unless valid?
    Person.transaction do
      person_model = create_person
      create_role(person_model)
    end
  end

  def set_privacy_policy_acceptance(value)
    person.privacy_policy_accepted = value
  end

  def valid?
    set_self_in_nested

    return current_step.valid?(self) unless last_step?

    steps.all? { |step| step.valid?(self) }
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

  def current_step
    steps[@step]
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

  def extract_attrs(params, key, permitted_attrs: PeopleController.permitted_attrs, array: false,
                    required: true)
    return {} if params.nil?

    params = required ?
               params.require(key).permit(*permitted_attrs) :
               params.permit(Hash[key, permitted_attrs])[key]
    array ? params&.values : params
  end

  def set_self_in_nested
    # For overriding in wagons
  end

end
