# == Schema Information
#
# Table name: events
#
#  id                     :integer          not null, primary key
#  group_id               :integer          not null
#  type                   :string(255)      not null
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
#  event_kind_id          :integer
#  state                  :string(60)
#  priorization           :boolean          default(FALSE), not null
#  requires_approval      :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class Event::Course < Event
  
  # states are used for workflow
  # translations in config/locales
  self.possible_states = %w(created confirmed application_open application_closed canceled completed closed)
  
  self.participation_types = [Event::Participation::Leader,
                              Event::Participation::AssistantLeader,
                              Event::Participation::Cook,
                              Event::Participation::Treasurer,
                              Event::Participation::Speaker,
                              Event::Course::Participation::Participant]
  
  attr_accessible :kind_id, :state, :priorization, :requires_approval
  
  
  # Define methods to query if a course is in the given state.
  # eg course.canceled?
  possible_states.each do |state|
    define_method "#{state}?" do
      self.state == state
    end
  end
  
end
