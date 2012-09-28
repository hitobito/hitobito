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
#  kind_id                :integer
#  state                  :string(60)
#  priorization           :boolean          default(FALSE), not null
#  requires_approval      :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class Event < ActiveRecord::Base

  class_attribute :participation_types, :possible_states 
  self.participation_types = [Event::Participation::Leader,
                              Event::Participation::AssistantLeader,
                              Event::Participation::Cook,
                              Event::Participation::Treasurer,
                              Event::Participation::Speaker,
                              Event::Participation::Participant]
  self.possible_states = []
  
  attr_accessible :name, :number, :motto, :cost, :maximum_participants, :contact_id, 
                  :description, :location, :application_opening_at, :application_closing_at,
                  :application_conditions, :dates_attributes

  ### ASSOCIATIONS

  belongs_to :group
  belongs_to :kind
  belongs_to :contact, class_name: 'Person'
  
  has_many :dates, dependent: :destroy, validate: true
  has_many :questions, dependent: :destroy, validate: true
  
  has_many :participations, dependent: :destroy
  has_many :people, through: :participations
  
  
  
  accepts_nested_attributes_for :dates, allow_destroy: true
  
  ### CALLBACKS
  
  
  # TODO: copy all event_questions without event_id into a newly created event (probably in controller, not here)

end
