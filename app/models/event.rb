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

  # This statement is required because this class would not be loaded otherwise.
  require_relative 'event/date'
  
  ### ATTRIBUTES

  class_attribute :participation_types, :participant_type, :possible_states 
  # All participation roles that exist for this event
  self.participation_types = [Event::Participation::Leader,
                              Event::Participation::AssistantLeader,
                              Event::Participation::Cook,
                              Event::Participation::Treasurer,
                              Event::Participation::Speaker,
                              Event::Participation::Participant]
  # The role of the participant
  self.participant_type = Event::Participation::Participant
  self.possible_states = []
  
  attr_accessible :name, :number, :motto, :cost, :maximum_participants, :contact_id, :contact,
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
  
  
  ### VALIDATIONS
  
  validate :assert_type_is_allowed_for_group
  # TODO validate application_closing_at is after opening_at if both are present
  
  
  ### CALLBACKS
  
  
  accepts_nested_attributes_for :dates, allow_destroy: true
  accepts_nested_attributes_for :questions, allow_destroy: true


  ### CLASS METHODS
  
  class << self
    def in_year(year)
      raise ArgumentError, "Invalid year: #{year}" if year.to_i <= 0
      start_at = DateTime.parse "#{year}-01-01"
      finish_at = DateTime.parse "#{year}-12-31"
      scoped
      .includes(:group, :kind, :dates)
      .joins(:group,:kind,:dates)
      .where(event_dates: { start_at: [start_at...finish_at] } )
      .order('event_kinds.id, groups.name')
    end

    def for_group(group_id)
      where(group_id: group_id)
    end
  end

  
  ### INSTANCE METHODS
  
  # May participants apply now?
  def application_possible?
    (!application_opening_at? || application_opening_at <= ::Date.today) &&
    (!application_closing_at? || application_closing_at >= ::Date.today) &&
    (maximum_participants.to_i == 0 || participant_count < maximum_participants)
  end

  def refresh_participant_count!
    count = people.where(event_participations: {type: participant_type.sti_name}).count(distinct: true)
    update_column(:participant_count, count)
  end

  def to_s
    name
  end
  
  private
  
  def assert_type_is_allowed_for_group
    if type && group && !group.class.event_types.collect(&:sti_name).include?(type)
      errors.add(:type, :type_not_allowed) 
    end
  end

end
