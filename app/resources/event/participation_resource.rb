# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationResource < ApplicationResource
  primary_endpoint "event_participations", [:index, :show]

  self.type = :event_participations

  with_options writable: false, filterable: false, sortable: false do
    attribute :event_id, :integer, filterable: true
    attribute :participant_id, :integer, filterable: true
    attribute :participant_type, :string, filterable: true
    attribute :application_id, :integer
    attribute :active, :boolean
    attribute :qualified, :boolean
    attribute :additional_information, :string
    attribute :created_at, :datetime
    attribute :updated_at, :datetime
  end

  belongs_to :event
  has_many :roles

  def base_scope
    super.list.active
  end

  def index_ability
    JsonApi::EventParticipationAbility.new(current_ability)
  end
end
