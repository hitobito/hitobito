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
    attribute :created_at, :datetime
    attribute :updated_at, :datetime
    attribute :deleted_at, :datetime
  end

  def index_ability
    JsonApi::RoleAbility.new(current_ability)
  end
end
