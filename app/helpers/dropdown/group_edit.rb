# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class GroupEdit < Base
    attr_reader :group

    def initialize(template, group)
      super(template, template.ti("link.edit"), :edit)

      @group = group
      @main_link = (group.archived? ? nil : template.edit_group_path(group))

      init_items
    end

    private

    def init_items
      setting_items
      add_divider
      action_items
    end

    def setting_items
      edit_service_token_item if template.can?(:index_service_tokens, group)
      edit_calendar_feeds_item
    end

    def action_items
      merge_group_item unless group.archived?
      move_group_item unless group.archived?
      archive_group_item if group.archivable?
      delete_group_item if !group.protected? && template.can?(:destroy, group)
    end

    # Dropdown items

    def edit_service_token_item
      add_item(translate(:edit_service_token), template.group_service_tokens_path(group))
    end

    def edit_calendar_feeds_item
      add_item(translate(:edit_calendar_feeds), template.group_calendars_path(group))
    end

    def merge_group_item
      add_item(translate(:merge), template.merge_group_path(group))
    end

    def move_group_item
      add_item(translate(:move), template.move_group_path(group))
    end

    def archive_group_item
      add_item(translate(:archive), template.archive_group_path(group),
        data: {confirm: template.ti(:confirm_archive), method: :post})
    end

    def delete_group_item
      add_divider unless group.archived?
      add_item(translate(:delete), template.group_path(group),
        data: {confirm: template.ti(:confirm_delete), method: :delete})
    end
  end
end
