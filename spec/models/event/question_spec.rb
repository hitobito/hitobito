# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_questions
#
#  id               :integer          not null, primary key
#  event_id         :integer
#  question         :string
#  choices          :string
#  multiple_choices :boolean          default(FALSE)
#  required         :boolean
#

require "spec_helper"

describe Event::Question do
  context "with an event assigned" do
    let(:event) { events(:top_course) }

    it "adds answer to participation after create" do
      expect do
        event.questions.create!(question: "Test?", disclosure: :required)
      end.to change { Event::Answer.count }.by(1)
    end
  end

  context "has validations" do
    subject { described_class.new(question: "Is this a Spec", disclosure: :optional) }

    it "is invalid without question" do
      subject.question = ""

      is_expected.to be_invalid
    end

    it "is valid without choices" do
      expect(subject.choice_items).to be_empty

      is_expected.to be_valid
    end
  end

  context "missing question" do
    it "admin has correct error message" do
      subject = described_class.new(admin: true, question: "", disclosure: :optional).tap(&:validate)
      expect(subject.errors.messages[:question]).to eq([
        I18n.t("activerecord.errors.models.event/question.attributes.question.admin_blank")
      ])
    end

    it "non-admin has correct error message" do
      subject = described_class.new(admin: false, question: "", disclosure: :optional).tap(&:validate)
      expect(subject.errors.messages[:question]).to eq([
        I18n.t("activerecord.errors.models.event/question.attributes.question.application_blank")
      ])
    end
  end

  context "with single-choice answer" do
    subject { described_class.new(question: "Test?", choices: "ja", disclosure: :optional) }

    it "knows that it only has one answer" do
      is_expected.to be_one_answer_available
    end

    it "may be required" do
      subject.disclosure = :required

      is_expected.to be_valid
    end

    it "may be optional" do
      subject.disclosure = :optional

      is_expected.to be_valid
    end
  end

  describe "#derive_for_existing_events" do
    subject { described_class.create(question: "Standard?", disclosure: :optional, event: nil) }

    let(:event) { events(:top_course) }
    let(:already_derived_question) do
      event.questions.create(question: "Already derived?", disclosure: :optional,
        event: event, derived_from_question: subject)
    end

    it "creates copies of the question for existing events" do
      already_derived_question
      derived_questions = subject.derive_for_existing_events
      expect(derived_questions.count).to eq(1)
      expect(derived_questions.map(&:event_id)).not_to include(event.id)
    end

    it "links existing answers to the new copies of the questions" do
      participation = Fabricate(:event_participation, event: event)
      answer = Event::Answer.create(question: subject, participation:, answer: "Existing")
      derived_questions = subject.derive_for_existing_events
      derived_question_for_event = derived_questions.find { _1.event_id == event.id }
      answer.reload
      expect(answer.question_id).to eq(derived_question_for_event.id)
    end
  end

  describe "#derive" do
    subject { described_class.create(question: "Standard?", disclosure: :optional, event: nil) }

    let(:event) { events(:top_course) }

    it "creates a copy of the question" do
      derived_question = subject.derive
      expect(derived_question.derived_from_question).to eq(subject)
      derived_question.event = event
      expect(derived_question).to be_valid
    end
  end
end
