# frozen_string_literal: true

#  Copyright (c) 2012-2022, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People::GroupRoles
  class Filter

    def initialize(group_id, list_filter_args)
      @group = Group.find(group_id)
      @list_filter_args = list_filter_args
    end

    def as_options
      { restrict_to_roles: role_sti_names,
        restrict_to_group_ids: group_ids }
    end

    private

    def group_ids
      group_ids = [@group.id]
      if deep?
        group_ids += group_children_ids
      elsif layer?
        group_ids += layer_group_ids
      end
      group_ids.uniq
    end

    def deep?
      arg = @list_filter_args[:range]
      range_arg&.eql?('deep')
    end

    def layer?
      range_arg&.eql?('layer')
    end

    def range_arg
      @list_filter_args[:range]
    end

    def group_children_ids
      @group.children.pluck(:id)
    end

    def layer_group_ids
      Group.where(layer_group_id: @group.id)
    end

    def role_sti_names
      if filter_role_ids.present?
        roles = Role.types_by_ids(filter_role_ids)
      else
        roles = @group.role_types
      end
      roles.collect(&:sti_name)
    end

    def filter_role_ids
      @list_filter_args
        &.fetch(:filters, nil)
        &.fetch(:role)
        &.fetch(:role_type_ids)
    end

  end
end
