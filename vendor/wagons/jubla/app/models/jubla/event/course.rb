module Jubla::Event::Course
  extend ActiveSupport::Concern
  
  included do
    include Event::RestrictedRole
    restricted_role :advisor, Event::Course::Role::Advisor
  
    attr_accessible :advisor_id, :application_contact_id
  
    # states are used for workflow
    # translations in config/locales
    self.possible_states = %w(created confirmed application_open application_closed canceled completed closed)

    ### ASSOCIATIONS

    belongs_to :application_contact, class_name: 'Group'
    
  
    ### VALIDATIONS
    
    validates :state, inclusion: possible_states

    validate :validate_application_contact
  
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

  def possible_contact_groups
    groups.each_with_object([]) do |g, contact_groups|
      if type = g.class.contact_group_type
        children = g.children.where(type: type.sti_name)
        contact_groups.concat(children)
      end
    end
  end

  private
  def validate_application_contact
    if possible_contact_groups.none? {|g| g == application_contact }
      errors.add(:application_contact_id, "muss definiert sein")
    end
  end
  
  module ClassMethods
    def application_possible
      where(state: 'application_open').
      where('events.application_opening_at IS NULL OR events.application_opening_at <= ?', ::Date.today)
    end
  end
  
end
