# encoding: UTF-8
class RoleDecorator < ApplicationDecorator
  decorates :role

  def used_attributes(*attributes)
    attributes.select { |name| model.class.attr_used?(name) }
  end

  def flash_info
    "<i>#{h.h(model)}</i> für <i>#{h.h(person)}</i> in <i>#{h.h(group)}</i>".html_safe
  end
end
