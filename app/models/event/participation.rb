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
  
  
  attr_accessible :additional_information, :answers_attributes
  
  
  ### ASSOCIATIONS
  
  belongs_to :event
  belongs_to :person
  
  has_many :answers, dependent: :destroy, validate: true
  
  # Actually, only an Event::Course::Participation::Participant has an application,
  # but that, unfortunately, does not work with rails associations.
  has_one :event_application, class_name: 'Event::Application', dependent: :destroy
  
  
  accepts_nested_attributes_for :answers, allow_destroy: true
  
end
