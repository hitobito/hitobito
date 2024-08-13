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
#  answer           :string(255)
#  participation_id :integer          not null
#  question_id      :integer          not null
#
# Indexes
#
#  index_event_answers_on_participation_id_and_question_id  (participation_id,question_id) UNIQUE
#

class Event::Answer < ActiveRecord::Base
  attr_writer :answer_required

  delegate :admin?, to: :question

  belongs_to :participation
  belongs_to :question

  # TODO
  attribute :answer, :json

  before_validation { question&.before_validate_answer(self) }

  validates_by_schema
  validates :question_id, uniqueness: {scope: :participation_id}
  validates :answer, presence: {if: lambda do
    question && question.required? && participation.enforce_required_answers
  end}
  validate :validate_with_question

  private

  def validate_with_question
    question.validate_answer(self)
  end

end
