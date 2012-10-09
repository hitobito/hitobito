# encoding: utf-8
class Event::ParticipationDecorator < ApplicationDecorator
  decorates 'event/participation'
  
  decorates_association :person
  
  delegate :to_s, :email, :all_phone_numbers, :complete_address, :all_social_accounts, to: :person
  
  # render a list of all participations
  def roles_short(event)
    h.safe_join(roles) do |r|
      content_tag(:p, r)
    end
  end

  def flash_info
    "von <i>#{h.h(person)}</i> in <i>#{h.h(event)}</i>".html_safe
  end
  
end