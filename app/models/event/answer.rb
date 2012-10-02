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


  validate :assert_answer_is_in_choice_items
  
  private
  
  def assert_answer_is_in_choice_items
    if question && question.choice_items.present? && !question.choice_items.include?(answer)
      errors.add(:answer, 'ist keine gültige Auswahl')
    end
  end
end
