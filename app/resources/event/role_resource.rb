# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::RoleResource < ApplicationResource
  self.type = "event_roles"

  with_options writable: false do
    attribute :participation_id, :integer
    attribute :type, :string
    attribute :label, :string
  end

  belongs_to :participation

  def base_scope
    Event::Role
  end
end
