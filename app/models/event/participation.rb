# encoding: utf-8

# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  event_id               :integer          not null
#  person_id              :integer          not null
#  created_at             :datetime         not null
#  additional_information :text
#  updated_at             :datetime         not null
#  active                 :boolean          default(FALSE), not null
#  application_id         :integer
#

class Event::Participation < ActiveRecord::Base
  
  schema_validations except_type: :uniqueness
  
  self.demodulized_route_keys = true
  
  attr_accessible :additional_information, :answers_attributes, :application_attributes
  
  
  ### ASSOCIATIONS
  
  belongs_to :event
  belongs_to :person
  
  belongs_to :application, dependent: :destroy, validate: true
  
  has_many :roles, dependent: :destroy

  has_many :answers, dependent: :destroy, validate: true

  
  
  accepts_nested_attributes_for :answers, :application
  
  
  ### VALIDATIONS
  
  validates :person_id, uniqueness: {scope: :event_id, message: 'Du hast dich für diesen Anlass bereits angemeldet.'}
  
  
  ### CALLBACKS
  
  before_validation :set_self_in_nested

  ### SCOPES
  scope :active, where(active: true)
  scope :pending, where(active: false)
  
  class << self
    # Order people by the order participation types are listed in their event types.
    def order_by_role(event_type)
      statement = "CASE event_roles.type "
      event_type.role_types.each_with_index do |t, i|
        statement << "WHEN '#{t.sti_name}' THEN #{i} "
      end
      statement << "END"
      joins(:roles).order(statement)
    end
    
    def upcoming
      joins(event: :dates).where('event_dates.start_at >= ?', ::Date.today).uniq
    end
    
    def leaders(event)
      joins(:roles).where('event_roles.type <> ?', event.participant_type.sti_name)
    end
    
    def participants(event)
      joins(:roles).where('event_roles.type = ?', event.participant_type.sti_name)
    end
    
    # load participations without affiliate roles
    def participating(event)
      affiliate_types = event.role_types.select(&:affiliate).collect(&:sti_name)
      if affiliate_types.present?
        joins(:roles).where("event_roles.type NOT IN (?)", affiliate_types)
      else
        scoped
      end
    end
  end


  ### INSTANCE METHODS

  def init_answers
    if answers.blank?
      event.questions.each do |q|
        a = q.answers.new
        a.question = q # without this, only the id is set
        self.answers << a
      end
    end
  end
  
  private
  
  def set_self_in_nested
    # don't try to set self in frozen nested attributes (-> marked for destroy)
    answers.each {|e| e.participation = self unless e.frozen? }
  end

end
