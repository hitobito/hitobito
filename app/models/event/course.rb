# == Schema Information
#
# Table name: events
#
#  id                     :integer          not null, primary key
#  type                   :string(255)
#  name                   :string(255)      not null
#  number                 :string(255)
#  motto                  :string(255)
#  cost                   :string(255)
#  maximum_participants   :integer
#  contact_id             :integer
#  description            :text
#  location               :text
#  application_opening_at :date
#  application_closing_at :date
#  application_conditions :text
#  kind_id                :integer
#  state                  :string(60)
#  priorization           :boolean          default(FALSE), not null
#  requires_approval      :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  participant_count      :integer          default(0)
#  application_contact_id :integer
#

class Event::Course < Event
  
  # This statement is required because this class would not be loaded otherwise.
  require_dependency 'event/course/role/participant'
  
  self.role_types = [Event::Role::Leader,
                     Event::Role::AssistantLeader,
                     Event::Role::Cook,
                     Event::Role::Treasurer,
                     Event::Role::Speaker,
                     Event::Course::Role::Participant]
  self.participant_type = Event::Course::Role::Participant
  self.supports_applications = true
  
  attr_accessible :number, :kind_id, :state, :priorization, :requires_approval

  belongs_to :kind
  
  validates :kind_id, presence: true
  
  
  class << self
    def in_hierarchy(user)
      only_group_id(groups_with_courses_in_hierarchy(user))
    end
    
    def groups_with_courses_in_hierarchy(user)
      Group.can_offer_courses.pluck(:id) & user.groups_hierarchy_ids
    end
    
  end

  def label_detail
    "#{kind.short_name} #{number} #{group_names}"
  end
  
  # The date on which qualification obtained in this course start
  def qualification_date
    @qualification_date ||= begin
      date = dates.reorder('event_dates.finish_at DESC').first
      if date && date.finish_at
        date.finish_at.to_date
      end
    end
  end
  
end
