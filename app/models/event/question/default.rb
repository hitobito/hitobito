# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_questions
#
#  id               :integer          not null, primary key
#  admin            :boolean          default(FALSE), not null
#  choices          :string(255)
#  multiple_choices :boolean          default(FALSE), not null
#  question         :text(65535)
#  required         :boolean          default(FALSE), not null
#  event_id         :integer
#
# Indexes
#
#  index_event_questions_on_event_id  (event_id)
#

class Event::Question::Default < Event::Question
  # translates :choices, class_name: Event::Question.to_s

  def choice_items
    choices.to_s.split(",").collect(&:strip)
  end

  def one_answer_available?
    choice_items.compact.one?
  end

  def with_choices?
    choice_items.present?
  end

  def with_checkboxes?
    multiple_choices? || one_answer_available?
  end

  def validate_answer(answer)
    # still allow answer to be nil because otherwise participations could not
    # be created without answering all questions (required to create roles for other people)
    if with_choices? &&
        answer &&
        multiple_choices? &&
        choice_items.include?(answer)
      answer.errors.add(:answer, :inclusion)
    end
  end

  # override to handle array values submitted from checkboxes
  def serialize_answer(value)
    return value unless with_choices? && with_checkboxes? && value.is_a?(Array)

    # have submit index + 1 and handle reset via index 0
    index_array = value.map { |i| i.to_i - 1 }

    valid_index_based_values(index_array, 0.upto(choice_items.size)) || nil
  end

  def valid_index_based_values(index_array, valid_range)
    indexes = index_array.map do |index|
      if valid_range.include?(index)
        choice_items[index]
      end
    end.compact

    indexes.present? ? indexes.join(", ") : nil
  end
end
