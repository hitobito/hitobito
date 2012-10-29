# encoding: utf-8
class Event::ParticipationDecorator < ApplicationDecorator
  decorates 'event/participation'
  
  decorates_association :person
  decorates_association :event
  decorates_association :application
  
  delegate :to_s, :email, :all_phone_numbers, :complete_address, :primary_email, :all_social_accounts, :town, to: :person
  delegate :priority, :confirmation, :waiting_list_link, to: :application
  
  # render a list of all participations
  def roles_short(event)
    h.safe_join(roles) do |r|
      content_tag(:p, r)
    end
  end

  def flash_info
    "von <i>#{h.h(person)}</i> in <i>#{h.h(event)}</i>".html_safe
  end
  
  def qualification_link
    h.toggle_link(qualified?, h.event_qualification_path(event_id, model))
  end

end
