# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.
module Wizards
  class Step
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    class_attribute :partial, instance_writer: false, instance_reader: false
    attr_reader :wizard

    def self.step_name
      model_name.element
    end
    delegate :step_name, to: :class
    delegate :current_user, to: :wizard

    def self.===(other)
      if other.is_a?(Class)
        self == other
      else
        step_name == other
      end
    end

    def initialize(wizard, **params)
      @wizard = wizard
      super(**params)
    end

    def partial
      self.class.partial.presence || self.class.name.underscore
    end

    def attr?(name)
      attribute_names.include?(name.to_s)
    end

    def contains_any_changes? = attributes.compact_blank != self.class._default_attributes.to_h.compact_blank
  end
end
