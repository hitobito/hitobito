# frozen_string_literal: true

#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PermittedGlobalizedAttrs
  def initialize(entry)
    @entry = entry
  end

  def permitted_attrs(original_permitted_attrs)
    return original_permitted_attrs unless Globalized.globalize_inputs?

    original_permitted_attrs.flat_map do |permitted_attr|
      next permit(permitted_attr, @entry.class)
    end
  end

  private

  def permit(permitted_attr, klass)
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
    if should_permit?(klass, permitted_attr)
      return [permitted_attr, *globalized_names_for_attr(permitted_attr)]
    end
    permitted_attr
  end

  def permit_hash(permitted_attr)
    permitted_attr.map do |k, v|
      if k.end_with?("_attributes")
        case v
        when Array
          next permit_relation_array(k, v)
        when Hash
          next {k => permit_hash(v)}
        else
          next {k => v}
        end
      end
      next {k => v}
    end.reduce(:merge)
  end

  def permit_relation_array(relation_name, relation_array)
    relation = relation_name.to_s.sub(/_[^_]*$/, "").to_sym
    klass = @entry.class.reflect_on_all_associations.find do |reflection|
      reflection.name == relation
    end&.klass
    return {relation_name => relation_array} if klass.blank?
    updated_relation_array = relation_array.flat_map do |permitted_attr|
      next permit(permitted_attr, klass)
    end
    {relation_name => updated_relation_array}
  end

  def should_permit?(klass, attr)
    klass.include?(Globalized) && klass.translated_attribute_names.include?(attr)
  end

  def globalized_names_for_attr(attr)
    Settings.application.languages.keys.excluding(I18n.locale).map { |lang| :"#{attr}_#{lang}" }
  end
end
