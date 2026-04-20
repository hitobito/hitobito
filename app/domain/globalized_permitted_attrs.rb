# frozen_string_literal: true

#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Expands permitted parameters to include globalized (language-specific) variants
# of translated attributes. This ensures that controller strong parameters allow
# all language fields (e.g., title_de, title_en, title_fr) when the base attribute
# (e.g., title) is permitted.
#
# Example:
#   permitted = [:name, :description]
#   GlobalizedPermittedAttrs.new(Group, permitted).permitted_attrs
#   => [:name, :description, :description_en, :description_fr, :description_it]
#
# Also handles nested attributes for associations that have globalized fields.
class GlobalizedPermittedAttrs
  def initialize(model_class, original_permitted_attrs)
    @model_class = model_class
    @original_permitted_attrs = original_permitted_attrs
  end

  # Returns the expanded list of permitted attributes including globalized variants.
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

  # Expands a symbol/string attribute to include its globalized variants if applicable.
  #
  # Example:
  #   permit_symbol(:title, Group)
  #   => [:title, :title_en, :title_fr, :title_it]
  def permit_symbol(permitted_attr, klass)
    return permitted_attr unless should_permit?(klass, permitted_attr)

    [permitted_attr.to_sym, *Globalized.globalized_names_for_attr(permitted_attr)]
  end

  # Processes a hash of permitted attributes (typically for nested attributes).
  # Recursively expands globalized attributes in nested structures by looking up
  # the association's model class and passing it through the expansion.
  #
  # Example:
  #   permit_hash({ questions_attributes: [:label, :text] }, Event)
  #   => { questions_attributes: [:label, :text, :text_en, :text_fr, :text_it] }
  def permit_hash(permitted_attr, klass)
    permitted_attr.map do |k, v|
      next {k => v} unless k.end_with?("_attributes")
      permit_nested_attributes(klass, k, v)
    end.reduce(:merge)
  end

  def permit_nested_attributes(klass, relation_name, permitted_attrs)
    assoc = get_association(relation_name, klass)
    return {relation_name => permitted_attrs} unless assoc
    # For polymorphic associations, we don't know the target type, so don't try to be smart.
    return {relation_name => permitted_attrs} if assoc.try(:options).try(:[], :polymorphic)

    case permitted_attrs
    when Array
      permit_relation_array(relation_name, permitted_attrs, assoc.klass)
    when Hash
      {relation_name => permit_hash(permitted_attrs, assoc.klass)}
    else
      {relation_name => permitted_attrs}
    end
  end

  # Handles nested attributes that are specified as an array.
  # Expands any globalized attributes in the nested array using the provided model class.
  #
  # Example: (text is translated, label is not)
  #   permit_relation_array(:questions_attributes, [:label, :text], Event::Question)
  #   => { questions_attributes: [:label, :text, :text_en, :text_fr, :text_it] }
  def permit_relation_array(relation_name, relation_array, klass)
    updated_relation_array = relation_array.flat_map do |permitted_attr|
      permit(permitted_attr, klass)
    end
    {relation_name => updated_relation_array}
  end

  # Extracts the association metadata for a nested association from its relation name.
  # Strips the '_attributes' suffix and looks up the association reflection.
  #
  # Example:
  #   get_association(:questions_attributes, Event)
  #   => #<ActiveRecord::Reflection::HasManyReflection:0x000073ee4207fab8>
  def get_association(relation_name, klass)
    relation = relation_name.to_s.sub(/_attributes$/, "").to_sym
    klass.reflect_on_all_associations.find do |reflection|
      reflection.name == relation
    end
  end

  # Checks if an attribute should be expanded to include globalized variants.
  # Returns true only if the class responds to translated_attribute_names and
  # the attribute is declared as translated.
  def should_permit?(klass, attr)
    klass.respond_to?(:translated_attribute_names) &&
      klass.translated_attribute_names.include?(attr.to_sym)
  end
end
