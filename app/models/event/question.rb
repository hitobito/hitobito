# encoding: utf-8
# == Schema Information
#
# Table name: event_questions
#
#  id               :integer          not null, primary key
#  event_id         :integer
#  question         :string(255)
#  choices          :string(255)
#  multiple_choices :boolean          default(FALSE)
#

class Event::Question < ActiveRecord::Base
  
  
  attr_accessible :question, :choices, :multiple_choices
  
  
  belongs_to :event
  
  has_many :answers, dependent: :destroy
  
  validate :assert_zero_or_more_than_one_choice
  
  
  scope :global, where(event_id: nil)
  
  
  def choice_items
    choices.to_s.split(',').collect(&:strip)
  end

  
  private
  
  def assert_zero_or_more_than_one_choice
    if choice_items.size == 1
      errors.add(:choices, "Bitte geben Sie mehrere mögliche Antworten an oder lassen Sie sie ganz leer.")
    end
  end
  
end
  
