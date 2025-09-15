# frozen_string_literal: true

#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PermittedGlobalizedAttrs do
  it "adds globalized version of permitted attrs" do
    with_globalized_models(Event)
    with_globalized_models(Event::Question)

    permitted_attrs = EventsController.permitted_attrs.deep_dup + Event.used_attributes.deep_dup
    permitted_globalized_attrs = described_class.new(Event).permitted_attrs(permitted_attrs)
    permitted_globalized_nested_attrs = permitted_globalized_attrs.find { |attr| attr.is_a? Hash }[:application_questions_attributes]

    expected_globalized_attrs = Event.globalize_attribute_names.filter { |a| !a.end_with?("_#{I18n.locale}") }
    expected_globalized_nested_attrs = Event::Question.globalize_attribute_names.filter { |a| !a.end_with?("_#{I18n.locale}") }

    expect(permitted_globalized_attrs).to include(*expected_globalized_attrs)
    expect(permitted_globalized_nested_attrs).to include(*expected_globalized_nested_attrs)
  end

  it "doesnt add globalized version of permitted attrs when base attr is not permitted" do
    with_globalized_models(Event)
    with_globalized_models(Event::Question)

    permitted_attrs = EventsController.permitted_attrs.deep_dup + Event.used_attributes.deep_dup

    removed_attr = permitted_attrs.delete(:name)
    removed_nested_attr = permitted_attrs.find { |attr| attr.is_a? Hash }[:application_questions_attributes].delete(:question)

    expect(removed_attr).not_to be_nil
    expect(removed_nested_attr).not_to be_nil

    permitted_globalized_attrs = described_class.new(Event).permitted_attrs(permitted_attrs)
    permitted_globalized_nested_attrs = permitted_globalized_attrs.find { |attr| attr.is_a? Hash }[:application_questions_attributes]

    expect(permitted_globalized_attrs).not_to include(:name_de, :name_en, :name_fr)
    expect(permitted_globalized_nested_attrs).not_to include(:question_de, :question_en, :question_fr)
  end
end
