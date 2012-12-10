# encoding: utf-8

class Event::Course::Condition < ActiveRecord::Base
  
  attr_accessible :content, :label
  
  belongs_to :group
  
  validate :assert_group_can_have_courses


  def to_s
    label
  end
  
  private
  
  def assert_group_can_have_courses
    if group && !group.event_types.include?(Event::Course)
      errors.add(:group_id, 'muss Kurse anbieten können')
    end
  end
end
