# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::KindCategoryResource < ApplicationResource
  self.type = "event_kind_categories"

  with_options writable: false, filterable: false, sortable: false do
    attribute :label, :string
  end

  def base_scope
    Event::KindCategory.where(deleted_at: nil).list
  end
end
