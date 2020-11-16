# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
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

require 'spec_helper'

describe Event::Answer do

  let(:question) { event_questions(:top_ov) }
  let(:choices) { question.choices.split(',') }

  context 'answer= for array values (checkboxes)' do
    subject { question.reload.answers.build }

    before do
      question.update_attribute(:multiple_choices, true) # rubocop:disable Rails/SkipsModelValidations
      subject.answer = answer_param
    end


    context 'valid array values (position + 1)' do
      let(:answer_param) { %w(1 2) }
      its(:answer) { should eq 'GA, Halbtax' }
      it { is_expected.to have(0).errors_on(:answer) }
    end

    context 'values outside of array size' do
      let(:answer_param) { %w(4 5) }
      its(:answer) { should be_nil }
    end

    context 'resetting values' do
      subject { question.reload.answers.build(answer: 'GA, Halbtax') }

      let(:answer_param) { ['0'] }
      its(:answer) { should be_nil }
    end
  end

end
