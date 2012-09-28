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
  
  attr_accessible :answer, :event_question_id
  
  belongs_to :participation
  belongs_to :question
  
end
