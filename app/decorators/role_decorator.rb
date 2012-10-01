# encoding: UTF-8
class RoleDecorator < ApplicationDecorator
  decorates :role

  def used_attributes(*attributes)
    attributes.select { |name| model.class.attr_used?(name) }
  end

  def flash_info
    "<i>#{model}</i> für <i>#{person}</i> in <i>#{group}</i>".html_safe
  end
end
