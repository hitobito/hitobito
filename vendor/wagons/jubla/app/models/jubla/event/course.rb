module Jubla::Event::Course
  extend ActiveSupport::Concern

  
  included do

    attr_accessible :advisor_id
    attr_writer :advisor_id

    self.role_types += [Role::Advisor]
    
    # states are used for workflow
    # translations in config/locales
    self.possible_states = %w(created confirmed application_open application_closed canceled completed closed)
    
    validates :state, inclusion: possible_states

    after_save :create_advisor

  
    # Define methods to query if a course is in the given state.
    # eg course.canceled?
    possible_states.each do |state|
      define_method "#{state}?" do
        self.state == state
      end
    end
  end
    
  # may participants apply now?
  def application_possible?
    application_open? && 
    (!application_opening_at || application_opening_at <= ::Date.today)
  end
  
  def qualification_possible?
    !completed? && !closed?
  end
  
  def state
    super || possible_states.first
  end

  def advisor
    @advisor ||= advisor_participation.try(:person)
  end

  def advisor_id
    @advisor_id ||= advisor.try(:id)
  end

  def advisor_participation
    @advisor_participation ||= participations.joins(:roles).where(event_roles: {type: Role::Advisor.sti_name}).first
  end

  private
  def create_advisor
    if advisor_participation.try(:person_id) != advisor_id
      if advisor_participation
        advisor_participation.roles.where(event_roles: {type: Role::Advisor.sti_name}).first.destroy
        @advisor_participation = nil # remove it from cache to
      end
      if advisor_id.present?
        participation = participations.where(person_id: advisor_id).first_or_create
        role = Role::Advisor.new
        role.participation = participation
        role.save!
      end
    end
  end
  
  module ClassMethods
    def application_possible
      where(state: 'application_open').
      where('events.application_opening_at IS NULL OR events.application_opening_at <= ?', ::Date.today)
    end
  end
  
  
  module Role
    class Advisor < ::Event::Role
     
      self.permissions = [:contact_data]
      self.restricted = true
      self.affiliate = true
    
    end
  end
  
end
