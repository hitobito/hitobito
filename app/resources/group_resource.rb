# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupResource < ApplicationResource
  attribute(:display_name, :string) { @object.display_name }
  attribute(:layer, :boolean) { @object.layer? }

  attributes_from_active_record(
    only: [
      :name,
      :short_name,
      :type,
      :email,
      :address,
      :zip_code,
      :town,
      :country,
      :created_at,
      :updated_at,
      :deleted_at
    ]
  )

  belongs_to :parent, resource: GroupResource, writable: false, foreign_key: :parent_id
  belongs_to :layer_group, resource: GroupResource, writable: false, foreign_key: :layer_group_id do
    assign do |_groups, _layer_groups|
      # We use the accessor from `NestedSet#layer_group` and there is no setter method,
      # so we skip this.
      # Note: this might lead to a performance penalty.
    end
  end
end
