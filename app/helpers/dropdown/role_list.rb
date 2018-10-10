# encoding: utf-8

#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class RoleList < Dropdown::Base

    attr_reader :group, :action

    def initialize(template, group, action, icon)
      label = translate(action)
      super(template, label, icon)
      @group = group
      @action = action
      init_items
    end

    private

    def init_items
      group.role_types.reject(&:restricted?).each do |type|
        send("role_item_#{action}", type)
      end
    end

    def role_item_move(type)
      link = template.move_group_role_list_path(group, role: { type: type.sti_name })
      add_item(type.label, link, data: { checkable: true, method: :get }, remote: true)
    end

    def role_item_remove(type)
      link = template.group_role_list_path(group, role: { type: type.sti_name })
      add_item(type.label, link, data: { checkable: true, method: :delete })
    end
  end
end
