# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::KindCategoryResource < ApplicationResource
  primary_endpoint "event_kind_categories", [:index, :show]

  self.type = "event_kind_categories"

  with_options writable: false, filterable: false, sortable: false do
    attribute :label, :string
    attribute :order, :integer
  end

  def base_scope
    Event::KindCategory.accessible_by(index_ability).where(deleted_at: nil).list
  end

  def index_ability
    JsonApi::EventAbility.new(current_ability)
  end
end
