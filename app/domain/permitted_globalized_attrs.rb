# frozen_string_literal: true

#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PermittedGlobalizedAttrs
  def permitted_attrs(original_permitted_attrs, entry)
    @entry = entry
    permitted_attrs = original_permitted_attrs.dup
    permitted_attrs.each do |permitted_attr|
      if permitted_attr.is_a?(Symbol) && should_permit?(@entry.class, permitted_attr)
        permitted_attrs.push(globalized_names_for_attr(permitted_attr))
      else
        globalize_nested_attrs(permitted_attr)
      end
    end
    permitted_attrs
  end

  private

  def globalize_nested_attrs(permitted_attr)
    if permitted_attr.is_a?(Hash)
      permitted_attr.each do |k, v|
        if k.end_with?("_attributes")
          if v.is_a?(Array)
            relation = k.to_s.sub(/_[^_]*$/, "")
            klass = @entry.send(relation).model
            v.each do |attr|
              v.push(globalized_names_for_attr(attr)) if should_permit?(klass, attr)
            end
          else
            globalize_nested_attrs(v)
          end
        end
      end
    end
  end

  def should_permit?(klass, attr)
    klass.include?(Globalized) && klass.translated_attribute_names.include?(attr)
  end

  def globalized_names_for_attr(attr)
    Settings.application.languages.keys.map { |lang| :"#{attr}_#{lang}" }
  end
end
