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
#  answer           :string(255)
#

class Event::Answer < ActiveRecord::Base

  attr_writer :answer_required

  delegate :admin?, to: :question

  belongs_to :participation
  belongs_to :question


  validates_by_schema
  validates :question_id, uniqueness: { scope: :participation_id }
  validates :answer, presence: { if: lambda do
    question && question.required? && participation.enforce_required_answers
  end }
  validate :assert_answer_is_in_choice_items

  # override to handle array values submitted from checkboxes
  def answer=(text)
    if question_with_choices? && question_with_checkboxes? && text.is_a?(Array)
      valid_range = (0...question.choice_items.size)
      # have submit index + 1 and handle reset via index 0
      index_array = text.map { |i| i.to_i - 1 }

      super(valid_index_based_values(index_array, valid_range) || nil)
    else
      super
    end
  end

  private

  def assert_answer_is_in_choice_items
    # still allow answer to be nil because otherwise participations could not
    # be created without answering all questions (required to create roles for other people)
    if question_with_choices? &&
       answer &&
       !question.multiple_choices? &&
       !question.choice_items.include?(answer)
      errors.add(:answer, :inclusion)
    end
  end

  def question_with_choices?
    question && question.choice_items.present?
  end

  def question_with_checkboxes?
    question.multiple_choices? || question.one_answer_available?
  end

  def valid_index_based_values(index_array, valid_range)
    indexes = index_array.map do |index|
      if valid_range.include?(index)
        question.choice_items[index]
      end
    end.compact

    indexes.present? ? indexes.join(', ') : nil
  end
end
