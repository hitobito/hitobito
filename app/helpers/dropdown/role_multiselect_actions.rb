# frozen_string_literal: true

#  Copyright (c) 2023, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class RoleMultiselectActions < Dropdown::Base

    attr_reader :params

    def initialize(template, group, translation, params)
      super(template, translation, :user)
      @template = template
      @group = group
      @params = params
      init_items
    end

    private

    def init_items
      add_item(I18n.t('people.multiselect_actions.role_actions.add'),
               template.new_group_role_list_path(@group),
               data: { checkable: true, method: :get },
               remote: true)

      add_item(I18n.t('people.multiselect_actions.role_actions.move'),
               template.move_group_role_list_path(@group, range: params[:range]),
               data: { checkable: true, method: :get },
               remote: true)

      add_item(I18n.t('people.multiselect_actions.role_actions.remove'),
               template.deletable_group_role_list_path(@group, range: params[:range]),
               data: { checkable: true, method: :get },
               remote: true)
    end
  end
end
