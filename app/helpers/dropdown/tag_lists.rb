# encoding: utf-8

#  Copyright (c) 2018, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class TagLists < Dropdown::Base

    def initialize(template, group, translation)
      super(template, translation, :tag)
      @template = template
      @group = group
      init_items
    end

    private

    def init_items
      add_item(I18n.t("people.multiselect_actions.add_tags"),
               template.new_group_tag_list_path(@group),
               data: { checkable: true, method: :get },
               remote: true)
      add_item(I18n.t("people.multiselect_actions.remove_tags"),
               template.deletable_group_tag_list_path(@group),
               data: { checkable: true, method: :get },
               remote: true)
    end
  end
end
