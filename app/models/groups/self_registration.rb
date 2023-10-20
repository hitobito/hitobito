# frozen_string_literal: true
#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Groups::SelfRegistration
  include ActiveModel::Model
  extend ActiveModel::Naming

  attr_accessor :group, :person_attributes, :step, :single

  # TODO switch from partials to view components
  class_attribute :partials, default: [:person]

  def initialize(group:, params:)
    @group = group
    @step = params[:step].to_i
    @person_attributes = extract_attrs(params, :person_attributes).to_h
  end

  def save!
    Person.transaction do
      person_model = create_person
      create_role(person_model)
    end
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
    @step == (partials.size - 1)
  end

  def first_step?
    @step.zero?
  end

  private

  def build_person(attrs, model_class = Person)
    model_class.new(attrs)
  end

  def create_person
    person.save!
  end

  def create_role(person)
    Role.create!(
      group: @group,
      type: @group.self_registration_role_type,
      person: person
    )
  end

  def extract_attrs(nested_params, key, array: false)
    params = nested_params.dig(self.class.model_name.param_key.to_sym, key).to_h
    array ? params.values : params
  end

end
