# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration
  include ActiveModel::Model

  attr_accessor :group, :main_person_attributes, :housemates_attributes, :single
  attr_reader :step, :next_step

  class_attribute :partials, default: [:main_person]

  def initialize(group:, params:)
    @group = group
    @step = params[:step].to_i
    @next_step = (params[:next] || @step + 1).to_i
    @main_person_attributes = extract_attrs(params, :main_person_attributes).to_h
  end

  def save!
    ::Person.transaction do
      main_person.save!
      yield if block_given?
    end
  end

  def valid?
    super && partials_valid?
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
    @step = first_invalid_or_next_step
  end

  private

  def first_invalid_or_next_step
    [next_step, partials.index(first_invalid_partial)].compact.min
  end

  def partials_valid?
    seen_partials.all? { |partial| send("#{partial}_valid?") }
  end

  def first_invalid_partial
    seen_partials.find { |partial| !send("#{partial}_valid?") }
  end

  def seen_partials
    partials.take(@step + 1)
  end

  def main_person_valid?
    main_person.valid?
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
