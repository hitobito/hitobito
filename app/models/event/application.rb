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
  
  attr_accessible :priority_1_id, :priority_2_id, :priority_3_id
  
  ### ASSOCIATION
  
  belongs_to :participation
  
  belongs_to :priority_1, class_name: 'Event' #::Course
  belongs_to :priority_2, class_name: 'Event' #::Course
  belongs_to :priority_3, class_name: 'Event' #::Course
  
end
