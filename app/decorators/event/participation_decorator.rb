# encoding: utf-8
class Event::ParticipationDecorator < ApplicationDecorator
  decorates 'event/participation'
  
  decorates_association :person
  decorates_association :event
  decorates_association :application
  
  delegate :to_s, :email, :all_phone_numbers, :complete_address, :all_social_accounts, to: :person
  
  # render a list of all participations
  def roles_short(event)
    h.safe_join(roles) do |r|
      content_tag(:p, r)
    end
  end

  def application_contact
    if application && application.contact 
      klass = application.contact.class.base_class
      decorator = "#{klass}Decorator".constantize.decorate(application.contact)
      h.render 'contactable/show', contactable: decorator, only_public: true
    end
  end

  def flash_info
    "von <i>#{h.h(person)}</i> in <i>#{h.h(event)}</i>".html_safe
  end
  
end
