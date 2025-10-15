#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Globalized model" do
  let(:group) { groups(:top_layer) }
  let(:custom_content) { custom_contents(:assignment_assignee_notification) }

  it "should create globalized accessors" do
    expected_values = {}
    Globalized.languages.each do |lang|
      title = "Privacy policy title in #{lang}"
      group.send(:"privacy_policy_title_#{lang}=", title)
      expect(group.send(:"privacy_policy_title_#{lang}")).to eql(title)
      expected_values[lang] = title
    end

    group.save!
    expect(group.privacy_policy_title_translations).to eql(expected_values.stringify_keys)
    Globalized.languages.each do |lang|
      expect(group.attributes.dig("privacy_policy_title_#{lang}")).to eql(group.send(:"privacy_policy_title_#{lang}"))
    end
  end

  it "should create globalized accessors for rich text fields" do
    expected_values = []
    Globalized.languages.each do |lang|
      body = "Custom content body {assignment-title} #{lang}"
      custom_content.send(:"body_#{lang}=", body)
      expect(custom_content.send(:"body_#{lang}").to_s).to include(body)
      expected_values.push(body)
    end

    custom_content.save!
    body_translations = custom_content.body_translations.values.map(&:to_s)

    body_translations.zip(expected_values) do |body_translation, expected_value|
      expect(body_translation).to include(expected_value)
    end
    Globalized.languages.each do |lang|
      expect(custom_content.attributes.dig("body_#{lang}").to_s).to eql(custom_content.send(:"body_#{lang}").to_s)
    end
  end

  it "should copy validators on globalized fields and add locale suffix to error messages" do
    Globalized.languages.each do |lang|
      group.send(:"privacy_policy_title_#{lang}=", "Long text" * 20)
    end

    expected_errors = [
      "DSE/Datenschutzerklärung Titel ist zu lang (mehr als 64 Zeichen)",
      "DSE/Datenschutzerklärung Titel (EN) ist zu lang (mehr als 64 Zeichen)",
      "DSE/Datenschutzerklärung Titel (FR) ist zu lang (mehr als 64 Zeichen)",
      "DSE/Datenschutzerklärung Titel (IT) ist zu lang (mehr als 64 Zeichen)"
    ]

    expect(group).not_to be_valid
    expect(group.errors.full_messages).to match_array(expected_errors)
  end

  it "should validate rich text placeholders on globalized fields" do
    Globalized.languages.each do |lang|
      custom_content.send(:"body_#{lang}=", "Text without placeholder")
    end

    expected_errors = [
      "Inhalt muss den Platzhalter {assignment-title} enthalten",
      "Inhalt (FR) muss den Platzhalter {assignment-title} enthalten",
      "Inhalt (EN) muss den Platzhalter {assignment-title} enthalten",
      "Inhalt (IT) muss den Platzhalter {assignment-title} enthalten"
    ]

    expect(custom_content).not_to be_valid
    expect(custom_content.errors.full_messages).to match_array(expected_errors)
  end

  it "should not copy presence validators" do
    expect(Event.validators_on(:name).any?(ActiveModel::Validations::PresenceValidator)).to be_truthy
    expect(Event.method_defined?(:name_en)).to be_truthy
    expect(Event.validators_on(:name_en).any?(ActiveModel::Validations::PresenceValidator)).to be_falsey
  end

  it "presence validated fields need current language filled in" do
    event = events(:top_event)
    event.name = ""
    expect(event).not_to be_valid
    event.name_fr = "French name"
    expect(event).not_to be_valid
  end
end
