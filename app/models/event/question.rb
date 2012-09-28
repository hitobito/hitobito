# == Schema Information
#
# Table name: event_questions
#
#  id       :integer          not null, primary key
#  event_id :integer
#  question :string(255)
#  choices  :string(255)
#

class Event::Question < ActiveRecord::Base
  
  
  attr_accessible :question, :choices
  
  
  belongs_to :event
  
  has_many :answers, dependent: :destroy
  
  
  # TODO: validate zero or more than one choices
  
  def choice_items
    choices.split(',').collect(&:strip)
  end
  
end
  
