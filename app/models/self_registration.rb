# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration
  include ActiveModel::Model
  extend ActiveModel::Naming

  attr_accessor :group, :main_person_attributes, :housemates_attributes, :step, :single

  class_attribute :partials, default: [:main_person]

  def initialize(group:, params:)
    @group = group
    @step = params[:step].to_i
    @main_person_attributes = extract_attrs(params, :main_person_attributes).to_h
  end

  def save!
    Person.transaction do
      person = main_person.person.tap(&:save!)
      @role = create_role(person)

      yield if block_given?
    end
  end

  def valid?
    main_person.valid?
  end

  def main_person
    @main_person ||= build_person(@main_person_attributes, MainPerson)
  end

  def main_person_email
    main_person.email
  end

  def main_person_role
    @role
  end

  def increment_step
    @step += 1
  end

  def last_step?
    @step == (partials.size - 1)
  end

  def first_step?
    @step.zero?
  end

  private

  def build_person(attrs, model_class)
    attrs = attrs.merge(extra_person_attrs)
    model_class.new(attrs)
  end

  def extra_person_attrs
    { primary_group_id: @group.id }
  end

  def create_role(person)
    Role.create!(role_attrs(person))
  end

  def role_attrs(person)
    {
      group: @group,
      type: @group.self_registration_role_type,
      person: person
    }
  end

  def extract_attrs(nested_params, key, array: false)
    params = nested_params.dig(self.class.model_name.param_key.to_sym, key).to_h
    array ? params.values : params
  end
end
