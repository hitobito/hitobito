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
#  answer           :string
#  participation_id :integer          not null
#  question_id      :integer          not null
#
# Indexes
#
#  index_event_answers_on_participation_id_and_question_id  (participation_id,question_id) UNIQUE
#

require "spec_helper"

describe Event::Answer do
  let(:question) { event_questions(:top_ov) }
  let(:participation) { question.event.participations.first }

  subject(:answer) { described_class.new(participation:, question:) }

  context "with required question" do
    before { question.update!(disclosure: :required) }

    it "validates required answer" do
      answer.participation.enforce_required_answers = true
      expect(answer).not_to be_valid
      expect(answer.errors[:answer]).to include("muss ausgefüllt werden")
    end
  end

  context "with custom validation on question" do
    it "calls the questions custom validation implementation" do
      expect(question).to receive(:validate_answer)
      expect(answer).to be_valid
    end
  end

  context "with question specific values" do
    it "calls the questions custom before_validation implementation" do
      expect(question).to receive(:before_validate_answer).and_return(true)
      answer.update!(answer: "Test")
      expect(answer.answer).to eq("Test")
    end
  end

  context ".list" do
    it "orders by questions and includes translations" do
      participation.init_answers
      ids = participation.answers.pluck(:id)

      list = []
      expect_query_count do
        list = participation.answers.list.to_a
        expect(list.map { |a| a.question.question })
          .to eq(["GA oder Halbtax?", "Ich bin Vegetarier", "Sonst noch was?"])
        expect(list.map(&:id)).to match_array(ids)
      end.to eq(3)
    end
  end
end
