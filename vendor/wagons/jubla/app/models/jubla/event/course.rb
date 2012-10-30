module Jubla::Event::Course
  extend ActiveSupport::Concern
  
  included do

    include Jubla::Event::Course::AffiliateAdvisor

    # states are used for workflow
    # translations in config/locales
    self.possible_states = %w(created confirmed application_open application_closed canceled completed closed)
    
    validates :state, inclusion: possible_states
  
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
  
  module ClassMethods
    def application_possible
      where(state: 'application_open').
      where('events.application_opening_at IS NULL OR events.application_opening_at <= ?', ::Date.today)
    end
  end
  
end
