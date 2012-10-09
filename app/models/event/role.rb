# == Schema Information
#
# Table name: event_roles
#
#  id               :integer          not null, primary key
#  type             :string(255)      not null
#  participation_id :integer          not null
#  label            :string(255)
#

class Event::Role < ActiveRecord::Base
  
  Permissions = [:full, :contact_data]

  include NormalizedLabels
  
  ### ATTRIBUTES

  class_attribute :permissions, :affiliate, :restricted
  self.permissions = []
  # Whether this participation is an active member or an affiliate person of the corresponding event.
  self.affiliate = false
  # Whether this kind of participation is specially managed or open for general modifications.
  self.restricted = false
  
  self.demodulized_route_keys = true
  
  attr_reader :person_id, :person
  
  attr_accessible :label
  
  
  ### ASSOCIATIONS
  
  belongs_to :participation, validate: true
  
  has_one :event, through: :participation
  has_one :person, through: :participation
  
  
  
  
  ### CALLBACKS
  
  after_create :set_participation_active
    
    
  ### INSTANCE METHODS
    
  def to_s
    model_name = self.class.model_name.human
    string = label? ? "#{label} (#{model_name})" : model_name
  end
  
  private
  
  # A participation with at least one role is active
  def set_participation_active
    participation.update_column(:active, true)
  end
  
end
