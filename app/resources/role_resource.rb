# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleResource < ApplicationResource
  attributes_from_active_record(only: [:person_id, :group_id, :label, :type, :created_at, :updated_at, :deleted_at ])
  relations_from_active_record(only: [:person, :group])

  has_one :layer_group, resource: GroupResource do
    params do |hash, roles|
      hash[:filter] = { id: roles.flat_map {|role| role.group.layer_group_id } }
    end
    assign do |_roles, _layer_groups|
      # We use the accessor from `NestedSet#layer_group` and there is no setter method, so we skip this.
      # Note: this might lead to a performance penalty.
    end
  end
end
