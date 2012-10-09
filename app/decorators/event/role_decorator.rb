# encoding: UTF-8
class Event::RoleDecorator < ApplicationDecorator
  decorates 'event/role'

  def flash_info
    "<i>#{h.h(model)}</i> für <i>#{h.h(participation.person)}</i> in <i>#{h.h(participation.event)}</i>".html_safe
  end
end
