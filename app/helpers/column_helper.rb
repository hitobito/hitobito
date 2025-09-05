#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ColumnHelper
  # Returns the ActiveRecord column type or nil.
  def column_type(obj, attr)
    return obj.send(:"#{attr}_type") if obj.respond_to?(:"#{attr}_type")

    attribute_type_enum(obj, attr) || column_property(obj, attr, :type)
  end

  def attribute_type_enum(obj, attr)
    :enum if obj.class.respond_to?(:attribute_types) &&
      obj.class.attribute_types[attr.to_s].is_a?(ActiveRecord::Enum::EnumType)
  end

  # Returns an ActiveRecord column property for the passed attr or nil
  def column_property(obj, attr, property)
    column = column_for_attr(obj, attr)
    if !column.nil? && column.respond_to?(property)
      obj.column_for_attribute(attr).send(property)
    elsif obj.respond_to?(:translation)
      column_property(obj.translation, attr, property)
    end
  end

  def column_for_attr(obj, attr)
    return nil unless obj.respond_to?(:column_for_attribute) && obj.has_attribute?(attr)
    obj.column_for_attribute(attr)
  end
end
