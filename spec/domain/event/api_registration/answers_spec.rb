# frozen_string_literal: true

#  Copyright (c) 2026, Berner Fachhochschule. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ApiRegistration::Answers do
  let(:event) { events(:top_event) }
  let!(:text) { Fabricate(:event_question, event:, question: "Allergien?") }
  let!(:radio) do
    Fabricate(:event_question, event:, question: "Essen?", choices: "Vegi,Fleisch",
      choices_fr: "Végé,Viande")
  end
  let!(:multiple) do
    Fabricate(:event_question, event:, question: "Tage?", choices: "Mo,Di,Mi",
      multiple_choices: true)
  end
  let(:submitted) do
    [
      {question_id: text.id, answer: "Nüsse"},
      {question_id: radio.id, answer: 1},
      {question_id: multiple.id, answer: [0, 2]}
    ]
  end
  let(:errors) { ActiveModel::Errors.new(Person.new) }

  def validate
    described_class.new(event, submitted).validate(errors)
    errors.details[:answers].pluck(:error)
  end

  describe "#validate" do
    it "accepts text, a choice index and a list of choice indices" do
      expect(validate).to be_empty
    end

    it "accepts string indices and missing optional answers" do
      submitted.replace([{"question_id" => radio.id.to_s, "answer" => "0"}])
      expect(validate).to be_empty
    end

    it "rejects questions of other events" do
      other = Fabricate(:event_question, event: events(:top_course))
      submitted << {question_id: other.id, answer: "x"}
      expect(validate).to eq [:unknown_question]
    end

    it "rejects admin questions" do
      admin = Fabricate(:event_question, event:, admin: true)
      submitted << {question_id: admin.id, answer: "x"}
      expect(validate).to eq [:unknown_question]
    end

    it "rejects questions answered twice" do
      submitted << {question_id: text.id, answer: "Milch"}
      expect(validate).to eq [:duplicate_question]
    end

    it "rejects choice indices out of range" do
      submitted[1][:answer] = 2
      submitted[2][:answer] = [0, 3]
      expect(validate).to eq [:invalid_answer, :invalid_answer]
    end

    it "rejects several choices for single choice questions" do
      submitted[1][:answer] = [0, 1]
      expect(validate).to eq [:invalid_answer]
    end

    it "rejects repeated choices" do
      submitted[2][:answer] = [1, 1]
      expect(validate).to eq [:invalid_answer]
    end

    it "rejects non text answers to free text questions" do
      submitted[0][:answer] = 42
      expect(validate).to eq [:invalid_answer]
    end

    it "requires answers to required questions" do
      text.update!(required: true)
      multiple.update!(required: true)
      submitted[0][:answer] = " "
      submitted[2][:answer] = []
      expect(validate).to eq [:required, :required]
    end
  end

  describe "#assign_to" do
    let(:participation) do
      event.participations.new(participant: people(:bottom_member)).tap do |p|
        p.roles.build(type: Event::Role::Participant.sti_name, participation: p)
      end
    end

    def answer_for(question)
      participation.answers.find { |a| a.question_id == question.id }.answer
    end

    it "stores choices as text in the given locale" do
      described_class.new(event, submitted).assign_to(participation, :fr)
      participation.save!

      expect(answer_for(text)).to eq "Nüsse"
      expect(answer_for(radio)).to eq "Viande"
      expect(answer_for(multiple)).to eq "Mo, Mi"
    end

    it "builds answers for unanswered questions and enforces required answers" do
      text.update!(required: true)
      described_class.new(event, submitted.drop(1)).assign_to(participation, :de)

      expect(participation.answers.map(&:question_id)).to include(text.id)
      expect(participation).not_to be_valid
    end
  end
end
