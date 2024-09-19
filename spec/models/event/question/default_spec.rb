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

describe Event::Question::Default do
  subject { described_class.new(question: "Is this a Spec") }

  context "has validations" do
    it "is invalid without question" do
      subject.question = ""

      is_expected.to be_invalid
    end

    it "is valid without choices" do
      expect(subject.choice_items).to be_empty

      is_expected.to be_valid
    end

    it "is valid with several choices" do
      subject.choices = "ja,nein,vielleicht"
      expect(subject.choice_items).to have(3).items

      is_expected.to be_valid
    end

    it "is valid with one choice" do
      subject.choices = "ja"
      expect(subject.choice_items).to have(1).item

      is_expected.to be_valid
    end
  end

  context "with single-choice answer" do
    subject { described_class.new(question: "Test?", choices: "ja") }

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

  describe "Event::Answer" do
    let(:question) { event_questions(:top_ov) }
    let(:choices) { question.choices.split(",") }

    context "answer= for array values (checkboxes)" do
      subject { question.reload.answers.build }

      before do
        question.update_attribute(:multiple_choices, true) # rubocop:disable Rails/SkipsModelValidations
        subject.answer = answer_param
        subject.save
      end

      context "valid array values (position + 1)" do
        let(:answer_param) { %w[1 2] }

        its(:answer) { is_expected.to eq "GA, Halbtax" }
        it { is_expected.to have(0).errors_on(:answer) }
      end

      context "values outside of array size" do
        let(:answer_param) { %w[4 5] }

        its(:answer) { is_expected.to be_nil }
      end

      context "resetting values" do
        subject { question.reload.answers.create(answer: "GA, Halbtax") }

        let(:answer_param) { ["0"] }

        its(:answer) { is_expected.to be_nil }
      end
    end

    context "validates answers to single-answer questions correctly: " do
      describe "a non-required question" do
        let(:question) { Fabricate(:event_question, disclosure: :optional, choices: "Ja") }

        subject(:no_answer_given) { build_answer("0") } # no choice

        subject(:yes_answer) { build_answer("1") }
        subject(:depends_answer) { build_answer("2") } # not a valid choice

        it "may be left unanswered" do
          expect(no_answer_given).to have(0).errors_on(:answer)
        end

        it "may be answered with the one option" do
          expect(yes_answer).to have(0).errors_on(:answer)
        end

        it "may not be answered with something else" do
          expect(depends_answer.answer).to be_nil
        end

        def build_answer(answer_index)
          question.answers.create(answer: [answer_index])
        end
      end
    end
  end
end
