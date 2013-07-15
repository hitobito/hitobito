# encoding: utf-8

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
  
  attr_accessible :answer, :question_id
  
  belongs_to :participation
  belongs_to :question


  validates :question_id, uniqueness: {scope: :participation_id}

  validate :assert_answer_is_in_choice_items

  # override to handle array values submitted from checkboxes
  def answer=(text)
    if question_with_choices? && question.multiple_choices? && text.is_a?(Array)
      valid_range = (0...question.choice_items.size)
      index_array = text.map(&:to_i).map { |i| i - 1 } # have submit index + 1 and handle reset via index 0

      super(valid_index_based_values(index_array,valid_range) || nil)
    else
      super
    end
  end

  private
  
  def assert_answer_is_in_choice_items
    # still allow answer to be nil because otherwise participations could not
    # be created without answering all questions (required to create roles for other people)
    if question_with_choices? && answer && !question.multiple_choices? && !question.choice_items.include?(answer)
      errors.add(:answer, 'ist keine gültige Auswahl')
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
