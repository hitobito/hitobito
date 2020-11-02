# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module UtilityHelper

  # Overridden method that takes a block that is executed for each item in array
  # before appending the results.
  def safe_join(array, sep = $OUTPUT_FIELD_SEPARATOR, &block)
    super(block_given? ? array.collect(&block).compact : array, sep)
  end

  # Returns the css class for the given flash level.
  def flash_class(level)
    case level
    when :notice then 'success'
    when :alert then 'error'
    else level.to_s
    end
  end

  # Adds a class to the given options, even if there are already classes.
  def add_css_class(options, classes)
    if options[:class]
      options[:class] += ' ' + classes
    else
      options[:class] = classes
    end
  end

  def model_class_label(entry)
    object_class(entry).model_name.human
  end

  # Returns the ActiveRecord column type or nil.
  def column_type(obj, attr)
    column_property(obj, attr, :type)
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
    return obj.column_for_attribute(attr)
  end

  # Returns the association proxy for the given attribute. The attr parameter
  # may be the _id column or the association name. If a macro (e.g. :belongs_to)
  # is given, the association must be of this type, otherwise, any association
  # is returned. Returns nil if no association (or not of the given macro) was
  # found.
  def association(obj, attr, *macros)
    klass = object_class(obj)
    if klass.respond_to?(:reflect_on_association)
      name = assoc_and_id_attr(attr).first.to_sym
      assoc = klass.reflect_on_association(name)
      assoc if assoc && (macros.blank? || macros.include?(assoc.macro))
    end
  end

  # Returns the name of the attr and it's corresponding field
  def assoc_and_id_attr(attr)
    attr = attr.to_s
    if attr.end_with?('_id')
      [attr[0..-4], attr]
    elsif attr.end_with?('_ids')
      [attr[0..-5].pluralize, attr]
    else
      [attr, "#{attr}_id"]
    end
  end

end
