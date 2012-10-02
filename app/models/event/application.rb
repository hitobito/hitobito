# == Schema Information
#
# Table name: event_applications
#
#  id               :integer          not null, primary key
#  participation_id :integer          not null
#  priority_1_id    :integer          not null
#  priority_2_id    :integer
#  priority_3_id    :integer
#  approved         :boolean          default(FALSE), not null
#  rejected         :boolean          default(FALSE), not null
#  waiting_list     :boolean          default(FALSE), not null
#

class Event::Application < ActiveRecord::Base
  
  self.demodulized_route_keys = true
  
  attr_accessible :priority_2_id, :priority_3_id,
                  :participation_attributes
  
  ### ASSOCIATION
  
  belongs_to :participation
  
  belongs_to :priority_1, class_name: 'Event' #::Course
  belongs_to :priority_2, class_name: 'Event' #::Course
  belongs_to :priority_3, class_name: 'Event' #::Course
  
  
  accepts_nested_attributes_for :participation



  def priority_1=(event)
    super
    self.participation = event.participant_type.new
    event.questions.each do |q|
      self.participation.answers << q.answers.new
    end
    event
  end
  
  def contact
    priority_1.contact
  end
end
