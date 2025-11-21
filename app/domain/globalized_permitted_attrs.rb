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
      permit_hash(permitted_attr, klass)
    else
      permitted_attr
    end
  end

  def permit_symbol(permitted_attr, klass)
    return permitted_attr unless should_permit?(klass, permitted_attr)

    [permitted_attr.to_sym, *Globalized.globalized_names_for_attr(permitted_attr)]
  end

  def permit_hash(permitted_attr, klass)
    permitted_attr.map do |k, v|
      if k.end_with?("_attributes") && (model_class = relation_class_from_name(k, klass))
        case v
        when Array
          permit_relation_array(k, v, model_class)
        when Hash
          {k => permit_hash(v, model_class)}
        else
          {k => v}
        end
      else
        {k => v}
      end
    end.reduce(:merge)
  end

  def permit_relation_array(relation_name, relation_array, klass)
    updated_relation_array = relation_array.flat_map do |permitted_attr|
      permit(permitted_attr, klass)
    end
    {relation_name => updated_relation_array}
  end

  def relation_class_from_name(relation_name, klass)
    relation = relation_name.to_s.sub(/_[^_]*$/, "").to_sym
    klass.reflect_on_all_associations.find do |reflection|
      reflection.name == relation
    end&.klass
  end

  def should_permit?(klass, attr)
    klass.respond_to?(:translated_attribute_names) &&
      klass.translated_attribute_names.include?(attr.to_sym)
  end
end
