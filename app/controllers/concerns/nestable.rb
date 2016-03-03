# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Provides functionality to nest controllers/resources.
# If a controller is nested, the parent classes and namespaces
# may be defined as an array in the :nesting class attribute.
# For example, a cities controller, nested in country and a admin
# namespace, may define this attribute as follows:
#   self.nesting = :admin, Country
module Nestable

  # Adds the :nesting class attribute and parent helper methods
  # to the including controller.
  def self.included(controller)
    controller.class_attribute :nesting

    controller.helper_method :parent, :parents

    controller.alias_method_chain :model_scope, :nesting
    controller.alias_method_chain :path_args, :nesting
  end

  private

  # Returns the direct parent ActiveRecord of the current request, if any.
  def parent
    parents.reverse.find { |p| p.is_a?(ActiveRecord::Base) }
  end

  # Returns the parent entries of the current request, if any.
  # These are ActiveRecords or namespace symbols, corresponding
  # to the defined nesting attribute.
  def parents
    nests = Array(nesting)
    @parents ||= nests.collect do |p|
      if p.is_a?(Class) && p < ActiveRecord::Base
        parent_entry(p)
      else
        p
      end
    end
  end

  # Loads the parent entry for the given ActiveRecord class.
  # By default, performs a find with the class_name_id param.
  def parent_entry(clazz)
    id = params["#{clazz.name.underscore}_id"]
    model_ivar_set(clazz.find(id))
  end

  # An array of objects used in url_for and related functions.
  def path_args_with_nesting(last)
    parents + [last]
  end

  # Uses the parent entry (if any) to constrain the model scope.
  def model_scope_with_nesting
    if parent.present?
      parent_scope
    else
      model_scope_without_nesting
    end
  end

  # The model scope for the current parent resource.
  def parent_scope
    parent.send(model_class.name.underscore.pluralize.split('/').last)
  end
end
