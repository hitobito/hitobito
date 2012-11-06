# encoding: UTF-8
class RoleDecorator < ApplicationDecorator
  decorates :role

  def used_attributes(*attributes)
    attributes.select { |name| model.class.attr_used?(name) }
  end

  def flash_info
    "<i>#{h.h(model)}</i> für <i>#{h.h(person)}</i> in <i>#{h.h(group)}</i>".html_safe
  end

  def possible_role_collection_select
    as_structs = GroupDecorator.decorate(group).possible_roles.map {|entry| OpenStruct.new(entry) }
    h.collection_select(:role, :type, as_structs, :sti_name, :human, {selected: model.type}, {class: 'span3'})
  end
end
