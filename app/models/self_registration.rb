# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration
  include ActiveModel::Model

  attr_accessor :group, :main_person_attributes, :housemates_attributes, :step, :single

  class_attribute :partials, default: [:main_person]

  def initialize(group:, params:)
    @group = group
    @step = params[:step].to_i
    @next = params[:next].to_i
    @main_person_attributes = extract_attrs(params, :main_person_attributes).to_h
  end

  def save!
    ::Person.transaction do
      main_person.save!
      People::DuplicateLocatorJob.new(main_person.person.id).enqueue!
      yield if block_given?
    end
  end

  def valid?
    super && validate_visited_partials
  end

  def main_person
    @main_person ||= build_person(@main_person_attributes, MainPerson)
  end

  def last_step?
    @step == (partials.size - 1)
  end

  def first_step?
    @step.zero?
  end

  def move_on
    @step = @next
  end

  private

  def validate_visited_partials
    visited_partials.all? do |partial|
      move_to_unless_valid?(partial, send("#{partial}_valid?"))
    end
  end

  def visited_partials
    partials.take(@step + 1).reverse
  end

  def main_person_valid?
    main_person.valid?
  end

  def move_to_unless_valid?(partial, valid)
    valid.tap do
      next if @step_resetted

      unless valid
        @step = partials.index(partial)
        @step_resetted = true
      end
    end
  end

  def build_person(attrs, model_class)
    attrs = yield attrs if block_given?
    model_class.new(attrs.merge(primary_group: group))
  end

  def extract_attrs(nested_params, key, array: false)
    params = nested_params.dig(self.class.model_name.param_key.to_sym, key).to_h
    array ? params.values : params
  end
end
