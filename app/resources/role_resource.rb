# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleResource < ApplicationResource
  # read-only for now
  attribute :person_id, :integer, writable: false
  attribute :group_id, :integer, writable: false
  attribute :label, :string, writable: false
  attribute :created_at, :datetime, writable: false
  attribute :updated_at, :datetime, writable: false
  attribute :deleted_at, :datetime, writable: false
end
