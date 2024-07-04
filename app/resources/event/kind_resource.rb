# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::KindResource < ApplicationResource
  primary_endpoint "event_kinds", [:index, :show]

  self.type = :event_kinds

  with_options writable: false, filterable: false, sortable: false do
    attribute :label, :string
    attribute :short_name, :string
    attribute :general_information, :string
    attribute :application_conditions, :string
    attribute :minimum_age, :integer
    attribute :created_at, :datetime
    attribute :updated_at, :datetime
  end

  belongs_to :kind_category, resource: Event::KindCategoryResource

  def base_scope
    Event::Kind.accessible_by(index_ability).where(deleted_at: nil).list
  end

  def index_ability
    JsonApi::EventAbility.new(current_ability)
  end
end
