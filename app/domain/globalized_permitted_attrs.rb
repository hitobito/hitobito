# frozen_string_literal: true

#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GlobalizedPermittedAttrs
  def initialize(model_class, original_permitted_attrs)
    @model_class = model_class
    @original_permitted_attrs = original_permitted_attrs
  end

  def permitted_attrs
    return @original_permitted_attrs unless Globalized.globalize_inputs?

    @original_permitted_attrs.flat_map do |permitted_attr|
      permit(permitted_attr)
    end
  end

  private

  def permit(permitted_attr, klass = @model_class)
    case permitted_attr
    when Symbol, String
      permit_symbol(permitted_attr, klass)
    when Hash
      permit_hash(permitted_attr)
    else
      permitted_attr
    end
  end

  def permit_symbol(permitted_attr, klass)
    return permitted_attr unless should_permit?(klass, permitted_attr)

    [permitted_attr, *Globalized.globalized_names_for_attr(permitted_attr)]
  end

  def permit_hash(permitted_attr)
    permitted_attr.map do |k, v|
      if k.end_with?("_attributes")
        case v
        when Array
          permit_relation_array(k, v)
        when Hash
          {k => permit_hash(v)}
        else
          {k => v}
        end
      else
        {k => v}
      end
    end.reduce(:merge)
  end

  def permit_relation_array(relation_name, relation_array)
    relation = relation_name.to_s.sub(/_[^_]*$/, "").to_sym
    klass = @model_class.reflect_on_all_associations.find do |reflection|
      reflection.name == relation
    end&.klass
    return {relation_name => relation_array} if klass.blank?
    updated_relation_array = relation_array.flat_map do |permitted_attr|
      permit(permitted_attr, klass)
    end
    {relation_name => updated_relation_array}
  end

  def should_permit?(klass, attr)
    klass.ancestors.include?(Globalized) && klass.translated_attribute_names.include?(attr)
  end
end
