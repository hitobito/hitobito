# encoding: utf-8
class Event::ParticipationDecorator < ApplicationDecorator
  decorates 'event/participation'
  
  def flash_info
    "<i>#{h.h(model)}</i> für <i>#{h.h(person)}</i> in <i>#{h.h(event)}</i>".html_safe
  end
end