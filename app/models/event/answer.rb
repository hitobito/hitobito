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
#  answer           :string(255)
#

class Event::Answer < ActiveRecord::Base

  attr_writer :answer_required

  belongs_to :participation
  belongs_to :question


  validates :question_id, uniqueness: { scope: :participation_id }
  validates :answer, presence: { if: lambda {
    question.required? && participation.enforce_required_answers
  } }
  validate :assert_answer_is_in_choice_items

  # override to handle array values submitted from checkboxes
  def answer=(text)
    if question_with_choices? && question.multiple_choices? && text.is_a?(Array)
      valid_range = (0...question.choice_items.size)
      # have submit index + 1 and handle reset via index 0
      index_array = text.map(&:to_i).map { |i| i - 1 }

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

  def valid_index_based_values(index_array, valid_range)
    indexes = index_array.map do |index|
      if valid_range.include?(index)
        question.choice_items[index]
      end
    end.compact

    indexes.present? ? indexes.join(', ') : nil
  end
end
