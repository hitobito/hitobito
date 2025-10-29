#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Globalized model" do
  let(:group) { groups(:top_layer) }
  let(:custom_content) { custom_contents(:assignment_assignee_notification) }

  it "should create globalized accessors" do
    privacy_policy_titles = Globalized.languages.each_with_object({}) do |lang, hash|
      hash[:"privacy_policy_title_#{lang}"] = "Privacy policy title in #{lang}"
    end

    group.update!(privacy_policy_titles)

    expect(group.privacy_policy_title_en).to eq("Privacy policy title in en")

    privacy_policy_title_translations = group.privacy_policy_title_translations
    expect(privacy_policy_title_translations.keys).to match_array(%w[de en fr it])
    expect(privacy_policy_title_translations.values).to eql(privacy_policy_titles.values)
    Globalized.languages.each do |lang|
      expect(group.attributes["privacy_policy_title_#{lang}"]).to eql(group.send(:"privacy_policy_title_#{lang}"))
    end
  end

  it "should create globalized accessors for rich text fields" do
    custom_content_bodies = Globalized.languages.each_with_object({}) do |lang, hash|
      hash[:"body_#{lang}"] = "Custom content body {assignment-title} #{lang}"
    end

    custom_content.update!(custom_content_bodies)

    expect(custom_content.body_fr.to_s).to include("Custom content body {assignment-title} fr")

    body_translations = custom_content.body_translations
    body_translations.transform_values!(&:to_s)
    expect(body_translations.keys).to match_array(%w[de en fr it])
    expect(body_translations.values.join).to include(*custom_content_bodies.values)
    Globalized.languages.each do |lang|
      expect(custom_content.attributes["body_#{lang}"].to_s).to eql(custom_content.send(:"body_#{lang}").to_s)
    end
  end

  it "should return translation for current locale when normal accessor is called" do
    group.update!({privacy_policy_title_de: "In german", privacy_policy_title_fr: "In french"})
    custom_content.update!({body_de: "In german {assignment-title}", body_fr: "In french {assignment-title}"})

    expect(group.privacy_policy_title).to eq(group.privacy_policy_title_de)
    expect(custom_content.body).to eq(custom_content.body_de)
    I18n.locale = :fr
    expect(group.privacy_policy_title).to eq(group.privacy_policy_title_fr)
    expect(custom_content.body).to eq(custom_content.body_fr)
  end

  it "should add locale suffix to human attribute name" do
    expected_attributes_human_attribute_names = {
      privacy_policy_title: "DSE/Datenschutzerklärung Titel",
      privacy_policy_title_de: "DSE/Datenschutzerklärung Titel (DE)",
      privacy_policy_title_en: "DSE/Datenschutzerklärung Titel (EN)",
      privacy_policy_title_fr: "DSE/Datenschutzerklärung Titel (FR)",
      privacy_policy_title_it: "DSE/Datenschutzerklärung Titel (IT)"
    }

    expected_attributes_human_attribute_names.each do |attr, human_attr_name|
      expect(Group.human_attribute_name(attr)).to eq(human_attr_name)
    end
  end

  it "should copy validators on globalized fields and use globalized human attribute names in error message" do
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

    I18n.locale = :fr

    expected_errors = [
      "Déclaration de protection des données - Titre est trop long (pas plus de 64 caractères)",
      "Déclaration de protection des données - Titre (DE) est trop long (pas plus de 64 caractères)",
      "Déclaration de protection des données - Titre (EN) est trop long (pas plus de 64 caractères)",
      "Déclaration de protection des données - Titre (IT) est trop long (pas plus de 64 caractères)"
    ]

    expect(group).not_to be_valid
    expect(group.errors.full_messages).to match_array(expected_errors)
  end

  it "should validate rich text placeholders on globalized custom content" do
    expected_errors = [
      "Inhalt muss den Platzhalter {assignment-title} enthalten",
      "Inhalt (FR) muss den Platzhalter {assignment-title} enthalten",
      "Inhalt (EN) muss den Platzhalter {assignment-title} enthalten",
      "Inhalt (IT) muss den Platzhalter {assignment-title} enthalten"
    ]

    Globalized.languages.each do |lang|
      custom_content.send(:"subject_#{lang}=", "")
      custom_content.send(:"body_#{lang}=", "Text without placeholder")
    end

    expect(custom_content).not_to be_valid
    expect(custom_content.errors.full_messages).to match_array(expected_errors)


    Globalized.languages.each do |lang|
      custom_content.send(:"subject_#{lang}=", "Text without placeholder")
      custom_content.send(:"body_#{lang}=", "")
    end

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
