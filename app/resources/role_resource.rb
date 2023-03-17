# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleResource < ApplicationResource
  # read-only for now
  with_options writable: false do
    attribute :person_id, :integer
    attribute :group_id, :integer
    attribute :label, :string
    attribute :type, :string
    attribute :created_at, :datetime
    attribute :updated_at, :datetime
    attribute :deleted_at, :datetime
  end

  belongs_to :person
  belongs_to :group

  has_one :layer_group, resource: GroupResource, writable: false do
    params do |hash, roles|
      hash[:filter] = { id: roles.flat_map {|role| role.group.layer_group_id } }
    end
    assign do |_roles, _layer_groups|
      # We use the accessor from `NestedSet#layer_group` and there is no setter method,
      # so we skip this.
      # Note: this might lead to a performance penalty.
    end
  end

  def index_ability
    JsonApi::RoleAbility.new(super)
  end
end
