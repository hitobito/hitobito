# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module DryCrud
  # Provide +before_render+ callbacks.
  module InstanceVariables
    # Get the instance variable named after the model_class.
    # If the collection variable is required, pass true as the second argument.
    def model_ivar_get(plural = false)
      name = ivar_name(model_class)
      name = name.pluralize if plural
      instance_variable_get(:"@#{name}")
    end

    # Sets an instance variable with the underscored class name if the given value.
    # If the value is a collection, sets the plural name.
    def model_ivar_set(value)
      name = if value.is_a?(ActiveRecord::Relation)
        ivar_name(value.klass).pluralize
      elsif value.respond_to?(:each) # Array
        ivar_name(value.first.class).pluralize
      else
        ivar_name(value.class)
      end
      instance_variable_set(:"@#{name}", value)
    end

    def ivar_name(klass)
      klass.base_class.name.demodulize.underscore
    end
  end
end
