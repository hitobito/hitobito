# == Schema Information
#
# Table name: event_applications
#
#  id            :integer          not null, primary key
#  priority_1_id :integer          not null
#  priority_2_id :integer
#  priority_3_id :integer
#  approved      :boolean          default(FALSE), not null
#  rejected      :boolean          default(FALSE), not null
#  waiting_list  :boolean          default(FALSE), not null
#

class Event::Application < ActiveRecord::Base
  
  self.demodulized_route_keys = true
  
  attr_accessible :priority_2_id, :priority_3_id
  
  ### ASSOCIATION
  
  has_one :participation
  
  has_one :event, through: :participation
  
  belongs_to :priority_1, class_name: 'Event' #::Course
  belongs_to :priority_2, class_name: 'Event' #::Course
  belongs_to :priority_3, class_name: 'Event' #::Course
  
  
  ## CLASS METHODS
  scope :pending, joins(:participation).where(event_participations: {active: false}, rejected: false) 

  
  def contact
    event.contact
  end
  
  def priority(event)
    [1,2,3].detect {|i| send("priority_#{i}_id") == event.id }
  end
end
