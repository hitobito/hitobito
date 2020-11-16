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

require 'spec_helper'

describe Event::Question do

  context 'with an event assigned' do
    let(:event) { events(:top_course) }

    it 'adds answer to participation after create' do
      expect do
        event.questions.create!(question: 'Test?', required: true)
      end.to change { Event::Answer.count }.by(1)
    end
  end

  context 'has validations' do
    subject { described_class.new(question: 'Is this a Spec') }

    it 'is valid without choices' do
      expect(subject.choice_items).to be_empty

      is_expected.to be_valid
    end

    it 'is valid with several choices' do
      subject.choices = 'ja,nein,vielleicht'
      expect(subject.choice_items).to have(3).items

      is_expected.to be_valid
    end

    it 'is valid with one choice' do
      subject.choices = 'ja'
      expect(subject.choice_items).to have(1).item

      is_expected.to be_valid
    end
  end

  context 'with single-choice answer' do
    subject { described_class.new(question: 'Test?', choices: 'ja') }

    it 'knows that it only has one answer' do
      is_expected.to be_one_answer_available
    end

    it 'may be required' do
      subject.required = true

      is_expected.to be_valid
    end

    it 'may be optional' do
      subject.required = false

      is_expected.to be_valid
    end
  end

end
