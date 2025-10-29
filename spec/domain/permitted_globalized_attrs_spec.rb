# frozen_string_literal: true

#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PermittedGlobalizedAttrs do
  let(:permitted_attrs) do
    [:globalized_attr, :other_globalized_attr, {
      related_test_model_attributes: [:globalized_relation_attr, :other_globalized_relation_attr]
    }]
  end

  let(:permitted_globalized_attrs) { described_class.new(TestModel, permitted_attrs).permitted_attrs }

  it "adds globalized version of permitted attrs except for current locale" do
    expected_globalized_attrs = attrs_with_globalized_versions(:globalized_attr, :other_globalized_attr)

    expect(permitted_globalized_attrs).to include(*expected_globalized_attrs)
    expect(permitted_globalized_attrs).not_to include(:globalized_attr_de, :other_globalized_attr_de)
  end

  it "doesnt add globalized version of permitted attrs when base attr not permitted" do
    permitted_attrs.delete(:other_globalized_attr)

    expected_globalized_attrs = attrs_with_globalized_versions(:globalized_attr)
    unexpected_globalized_attrs = attrs_with_globalized_versions(:other_globalized_attr, only_additional: false)

    expect(permitted_globalized_attrs).to include(*expected_globalized_attrs)
    expect(permitted_globalized_attrs).not_to include(*unexpected_globalized_attrs)
  end

  it "adds globalized version of permitted attrs for relations except for current locale" do
    permitted_globalized_relation_attrs =
      permitted_globalized_attrs.find { |attr| attr.is_a? Hash }[:related_test_model_attributes]

    expected_globalized_relation_attrs =
      attrs_with_globalized_versions(:globalized_relation_attr, :other_globalized_relation_attr)

    expect(permitted_globalized_relation_attrs).to include(*expected_globalized_relation_attrs)
    expect(permitted_globalized_relation_attrs).not_to include(
      :globalized_relation_attr_de, :other_globalized_relation_attr_de
    )
  end

  it "doesnt add globalized version of permitted attrs for relations when base attr not permitted" do
    permitted_attrs.find { |attr| attr.is_a? Hash }[:related_test_model_attributes]
      .delete(:other_globalized_relation_attr)

    permitted_globalized_relation_attrs =
      permitted_globalized_attrs.find { |attr| attr.is_a? Hash }[:related_test_model_attributes]

    expected_globalized_relation_attrs =
      attrs_with_globalized_versions(:globalized_relation_attr)
    unexpected_globalized_relation_attrs =
      attrs_with_globalized_versions(:other_globalized_relation_attr, only_additional: false)

    expect(permitted_globalized_relation_attrs).to include(*expected_globalized_relation_attrs)
    expect(permitted_globalized_relation_attrs).not_to include(*unexpected_globalized_relation_attrs)
  end

  def attrs_with_globalized_versions(*attrs, only_additional: true)
    (attrs + attrs.map { |attr| Globalized.globalized_names_for_attr(attr, only_additional) }).flatten
  end
end

class TestModel
  def self.include?(module_)
    return true if module_ == Globalized

    super
  end

  def self.translated_attribute_names
    %i[globalized_attr other_globalized_attr]
  end

  def self.reflect_on_all_associations
    [StubbedReflection.new]
  end
end

class RelatedTestModel
  def self.include?(module_)
    return true if module_ == Globalized

    super
  end

  def self.translated_attribute_names
    %i[globalized_relation_attr other_globalized_relation_attr]
  end
end

class StubbedReflection
  def name
    :related_test_model
  end

  def klass
    RelatedTestModel
  end
end
