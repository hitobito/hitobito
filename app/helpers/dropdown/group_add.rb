# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class GroupAdd < Base

    attr_reader :group

    def initialize(template, group)
      super(template, template.ti('link.add', model: Group.model_name.human), :plus)
      @group = group
      init_items
    end

    private

    def init_items
      group.possible_children.each do |type|
        if template.can?(:create, type.new(parent: group))
          link = template.new_group_path(group: { parent_id: group.id, type: type.sti_name })
          add_item(type.label, link)
        end
      end
    end

  end
end
