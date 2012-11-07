module Jubla::Ability
  extend ActiveSupport::Concern
  
  
  included do
    alias_method_chain :initialize, :jubla
  end
  
  def initialize_with_jubla(user)
    initialize_without_jubla(user)

    customize_for_closed_events
  end

  # important, cannot statements have to go at the end to override previous can statements
  # if can statements are missing, returning false from cannot statements does not allow the action
  def customize_for_closed_events
    cannot [:application_market, :update, :destroy, :qualify], Event do |event|
      is_closed_course?(event) && !admin
    end

    cannot [:create, :update, :destroy], Event::Participation do |participation|
      is_closed_course?(participation.event) && !admin
    end

    cannot :manage, Event::Role do |event_role|
      is_closed_course?(event_role.event) && !admin
    end
  end


  private
  def is_closed_course?(event)
    event.kind_of?(Event::Course) && event.state == 'closed'
  end
  
end
