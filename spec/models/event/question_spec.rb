# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::Question do
  context "with an event assigned" do
    let(:event) { events(:top_course) }

    it "adds answer to participation after create" do
      expect do
        event.questions.create!(question: "Test?", required: true)
      end.to change { Event::Answer.count }.by(1)
    end
  end

  context "has validations" do
    subject { described_class.new(question: "Is this a Spec", required: false) }

    it "is invalid without question" do
      subject.question = ""

      is_expected.to be_invalid
    end
  end

  context "missing question" do
    it "admin has correct error message" do
      subject = described_class.new(admin: true, question: "", required: false).tap(&:validate)
      expect(subject.errors.messages[:question]).to eq([
        I18n.t("activerecord.errors.models.event/question.attributes.question.admin_blank")
      ])
    end

    it "non-admin has correct error message" do
      subject = described_class.new(admin: false, question: "", required: false).tap(&:validate)
      expect(subject.errors.messages[:question]).to eq([
        I18n.t("activerecord.errors.models.event/question.attributes.question.application_blank")
      ])
    end
  end

  context "with single-choice answer" do
    subject { described_class.new(question: "Test?", required: false) }

    it "may be required" do
      subject.required = true

      is_expected.to be_required
      is_expected.to be_valid
    end

    it "may be optional" do
      subject.required = false

      is_expected.not_to be_required
      is_expected.to be_valid
    end
  end

  describe "#copy_translations_for_derived_question" do
    it "does copy tranlsations from global questions on create" do
      event = Fabricate.build(:event, dates: [Event::Date.new(start_at: 1.day.ago)])
      event.init_questions
      event.application_questions.each do
        empty_payload = _1.class.globalize_attribute_names
          .reject { |attribute| attribute.to_s.include?("de") }
          .index_with(nil)
        _1.assign_attributes(empty_payload)
      end
      event.save!

      expect(event.reload.questions.map(&:question_fr)).to eq [
        "J'ai l'abonnement de transports publics suivant",
        nil,
        nil
      ]
    end
  end

  describe "#deserialized_choices" do
    let(:event) { events(:top_course) }
    let(:question) { event.application_questions.first }

    it "should return choices if only one translation is filled out and others are empty strings" do
      question.choices_translations = {de: "Ja, Nein", en: "", fr: "", it: ""}

      choices = question.deserialized_choices

      expect(choices.length).to eql(2)
      expect(choices.first.choice_translations).to eql({de: "Ja", en: "", fr: "", it: ""})
      expect(choices.second.choice_translations).to eql({de: "Nein", en: "", fr: "", it: ""})
    end

    it "should return choices if only one translation is filled out and others are nil" do
      question.choices_translations = {de: nil, en: "Yes, No", fr: nil, it: nil}

      choices = question.deserialized_choices

      expect(choices.length).to eql(2)
      expect(choices.first.choice_translations).to eql({de: "", en: "Yes", fr: "", it: ""})
      expect(choices.second.choice_translations).to eql({de: "", en: "No", fr: "", it: ""})
    end

    it "should return all translations" do
      question.choices_translations = {
        de: "Ja, Nein, Vielleicht",
        en: "Yes,No,Maybe",
        fr: "Oui, Non, Peut-être",
        it: "Sì, No, Forse"
      }

      choices = question.deserialized_choices

      expect(choices.length).to eql(3)
      expect(choices.first.choice_translations).to eql({de: "Ja", en: "Yes", fr: "Oui", it: "Sì"})
      expect(choices.second.choice_translations).to eql({de: "Nein", en: "No", fr: "Non", it: "No"})
      expect(choices.third.choice_translations).to eql({de: "Vielleicht", en: "Maybe", fr: "Peut-être", it: "Forse"})
    end

    it "should return all translations if number of questions is not the same in all languages" do
      question.choices_translations = {
        de: "Ja, Nein, Vielleicht",
        en: "Yes,No",
        fr: "Oui,,Peut-être",
        it: ",No"
      }

      choices = question.deserialized_choices

      expect(choices.length).to eql(3)
      expect(choices.first.choice_translations).to eql({de: "Ja", en: "Yes", fr: "Oui", it: ""})
      expect(choices.second.choice_translations).to eql({de: "Nein", en: "No", fr: "", it: "No"})
      expect(choices.third.choice_translations).to eql({de: "Vielleicht", en: "", fr: "Peut-être", it: ""})
    end

    it "should return escaped commas as comma" do
      question.choices_translations = {
        de: "Wahl 1,Wahl\\u002C 2",
        en: "Choice 1,Choice\\u002C 2"
      }

      choices = question.deserialized_choices

      expect(choices.length).to eql(2)
      expect(choices.first.choice_translations).to eql({de: "Wahl 1", en: "Choice 1", fr: "", it: ""})
      expect(choices.second.choice_translations).to eql(
        {de: "Wahl, 2", en: "Choice, 2", fr: "", it: ""}
      )
    end

    it "should return empty array if all translations are empty strings" do
      Globalized.languages.each do |lang|
        question.send(:"choices_#{lang}=", "")
      end

      expect(question.deserialized_choices).to eql([])
    end

    it "should return empty array if all translations are nil" do
      Globalized.languages.each do |lang|
        question.send(:"choices_#{lang}=", nil)
      end

      expect(question.deserialized_choices).to eql([])
    end
  end

  describe "#choices_attributes=" do
    let(:event) { events(:top_course) }
    let(:question) { event.application_questions.first }

    it "should correctly serialize choices" do
      choices_attributes = {"100": {choice: "Ja", choice_en: "Yes", choice_fr: "Oui", choice_it: "Sì", _destroy: ""},
                            "101": {choice: "", choice_en: "", choice_fr: "", choice_it: "", _destroy: ""},
                            "102": {choice: "Nein", choice_en: "No", choice_fr: "Non", choice_it: "No", _destroy: ""}}
      choices_attributes.deep_stringify_keys!

      question.choices_attributes = choices_attributes
      question.save!

      expect(question.reload.deserialized_choices.length).to eql(2)

      expect(question.choices_translations).to eql(
        {de: "Ja,Nein", en: "Yes,No", fr: "Oui,Non", it: "Sì,No"}.stringify_keys
      )
    end

    it "should correctly serialize choices when locale is changed" do
      I18n.locale = :fr
      choices_attributes = {"100": {choice: "Oui", choice_de: "Ja", choice_en: "Yes", choice_it: "Sì", _destroy: ""},
                            "101": {choice: "", choice_en: "", choice_fr: "", choice_it: "", _destroy: ""},
                            "102": {choice: "Non", choice_de: "Nein", choice_en: "No", choice_it: "No", _destroy: ""}}
      choices_attributes.deep_stringify_keys!

      question.choices_attributes = choices_attributes
      question.save!

      expect(question.reload.deserialized_choices.length).to eql(2)

      expect(question.choices_translations).to eql(
        {de: "Ja,Nein", en: "Yes,No", fr: "Oui,Non", it: "Sì,No"}.stringify_keys
      )
    end

    it "should escape commas in choices" do
      choices_attributes = {
        "100": {choice: "Wahl 1", choice_en: "Choice 1", choice_fr: "", choice_it: "", _destroy: ""},
        "101": {choice: "Wahl, 2", choice_en: "Choice, 2", choice_fr: "", choice_it: "", _destroy: ""}
      }
      choices_attributes.deep_stringify_keys!

      question.choices_attributes = choices_attributes
      question.save!

      expect(question.reload.deserialized_choices.length).to eql(2)

      expect(question.choices_translations).to eql(
        {de: "Wahl 1,Wahl\\u002C 2", en: "Choice 1,Choice\\u002C 2", fr: ",", it: ","}.stringify_keys
      )
    end

    it "should save choices as empty strings if all choices are empty" do
      choices_attributes = {"100": {choice: "", choice_en: "", choice_fr: "", choice_it: "", _destroy: ""},
                            "101": {choice: nil, choice_en: nil, choice_fr: nil, choice_it: nil, _destroy: nil}}
      choices_attributes.deep_stringify_keys!

      question.choices_attributes = choices_attributes
      question.save!

      expect(question.reload.deserialized_choices).to eql([])

      expect(question.choices_translations).to eql({de: "", en: "", fr: "", it: ""}.stringify_keys)
    end

    it "should delete choices that are marked for deletion" do
      choices_attributes = {"100": {choice: "Del", choice_en: "Del", choice_fr: "Del", choice_it: "Del", _destroy: "1"},
                            "101": {choice: "Ja", choice_en: "Yes", choice_fr: "Oui", choice_it: "Sì", _destroy: ""}}
      choices_attributes.deep_stringify_keys!

      question.choices_attributes = choices_attributes
      question.save!

      expect(question.reload.deserialized_choices.length).to eql(1)

      expect(question.choices_translations).to eql({de: "Ja", en: "Yes", fr: "Oui", it: "Sì"}.stringify_keys)
    end
  end

  context "paper trails", versioning: true do
    let(:event) { events(:top_course) }

    it "sets main to event on create" do
      expect do
        event.questions.create!(question: "Warum ist die Banane krumm?", required: true)
      end.to change {
               PaperTrail::Version.count
             }.by(3) # creates a version for answers, one per participation and one version for the translation

      version = PaperTrail::Version.where(item_type: Event::Question.sti_name).order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(event)
    end

    it "sets main to event on update" do
      expect do
        event.questions.first.update!(required: true)
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("update")
      expect(version.main).to eq(event)
    end
  end
end
