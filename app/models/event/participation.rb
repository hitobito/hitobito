# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  event_id               :integer
#  person_id              :integer          not null
#  type                   :string(255)      not null
#  label                  :string(255)
#  additional_information :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class Event::Participation < ActiveRecord::Base
  
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
  
  attr_accessible :label, :additional_information, :answers_attributes
  
  
  ### ASSOCIATIONS
  
  belongs_to :event
  belongs_to :person
  
  has_many :answers, dependent: :destroy, validate: true
  
  # Actually, only an Event::Course::Participation::Participant has an application,
  # but that, unfortunately, does not work with rails associations.
  has_one :event_application, class_name: 'Event::Application', dependent: :destroy
  
  
  accepts_nested_attributes_for :answers
  
  
  ### CALLBACKS
  
  before_validation :set_self_in_nested

  
  ### INSTANCE METHODS
    
  def to_s
    model_name = self.class.model_name.human
    string = label? ? "#{label} (#{model_name})" : model_name
  end
  
  
  private
  
  def set_self_in_nested
    # don't try to set self in frozen nested attributes (-> marked for destroy)
    answers.each {|e| e.participation = self unless e.frozen? }
  end

end
