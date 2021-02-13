# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_answers
#
#  id               :integer          not null, primary key
#  participation_id :integer          not null
#  question_id      :integer          not null
#  answer           :string
#

require "spec_helper"

describe Event::Answer do
  let(:question) { event_questions(:top_ov) }
  let(:choices) { question.choices.split(",") }

  context "answer= for array values (checkboxes)" do
    subject { question.reload.answers.build }

    before do
      question.update_attribute(:multiple_choices, true) # rubocop:disable Rails/SkipsModelValidations
      subject.answer = answer_param
    end

    context "valid array values (position + 1)" do
      let(:answer_param) { %w(1 2) }

      its(:answer) { should eq "GA, Halbtax" }
      it { is_expected.to have(0).errors_on(:answer) }
    end

    context "values outside of array size" do
      let(:answer_param) { %w(4 5) }

      its(:answer) { should be_nil }
    end

    context "resetting values" do
      subject { question.reload.answers.build(answer: "GA, Halbtax") }

      let(:answer_param) { ["0"] }

      its(:answer) { should be_nil }
    end
  end

  context "validates answers to single-answer questions correctly: " do
    describe "a non-required question" do
      let(:question) { Fabricate(:event_question, required: false, choices: "Ja") }

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
        event_answer = question.answers.build
        event_answer.answer = [answer_index]
        event_answer
      end
    end
  end
end
