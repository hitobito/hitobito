#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Globalized model" do
  let(:group) { groups(:top_layer) }
  let(:custom_content) { custom_contents(:assignment_assignee_notification) }
  let(:languages) { Settings.application.languages.keys }

  before do
    allow(Settings.application).to receive(:languages).and_return({de: "Deutsch", en: "English", fr: "Français"})
    Group.globalize_accessors
    CustomContent.globalize_accessors
    Group.copy_validators_to_globalized_accessors
    CustomContent.copy_validators_to_globalized_accessors
  end

  it "should create globalized accessors" do
    expected_values = {}
    languages.each do |lang|
      title = "Privacy policy title in #{lang}"
      group.send(:"privacy_policy_title_#{lang}=", title)
      expect(group.send(:"privacy_policy_title_#{lang}")).to eql(title)
      expected_values[lang] = title
    end

    group.save!
    expect(group.privacy_policy_title_translations).to eql(expected_values.stringify_keys)
  end

  it "should create globalize accessors for rich text fields" do
    expected_values = []
    languages.each do |lang|
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
  end

  it "should copy validators on globalized fields and add locale suffix to error messages" do
    languages.each do |lang|
      group.send(:"privacy_policy_title_#{lang}=", "Long text" * 20)
    end

    expected_errors = [
      "DSE/Datenschutzerklärung Titel ist zu lang (mehr als 64 Zeichen)",
      "DSE/Datenschutzerklärung Titel (EN) ist zu lang (mehr als 64 Zeichen)",
      "DSE/Datenschutzerklärung Titel (FR) ist zu lang (mehr als 64 Zeichen)"
    ]

    expect(group).not_to be_valid
    expect(group.errors.full_messages).to match_array(expected_errors)
  end

  it "should validate rich text placeholders on globalized fields" do
    languages.each do |lang|
      custom_content.send(:"body_#{lang}=", "Text without placeholder")
    end

    expected_errors = [
      "Inhalt muss den Platzhalter {assignment-title} enthalten",
      "Inhalt (FR) muss den Platzhalter {assignment-title} enthalten",
      "Inhalt (EN) muss den Platzhalter {assignment-title} enthalten"
    ]

    expect(custom_content).not_to be_valid
    expect(custom_content.errors.full_messages).to match_array(expected_errors)
  end
end
