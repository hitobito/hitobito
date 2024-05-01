# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::DateResource < ApplicationResource
  with_options writable: false, filterable: false, sortable: false do
    attribute :event_id, :integer, filterable: true
    attribute :label, :string
    attribute :location, :string
    attribute :start_at, :datetime
    attribute :finish_at, :datetime
  end

  belongs_to :event

  def base_scope
    Event::Date
  end
end
