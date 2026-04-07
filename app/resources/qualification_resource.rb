# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class QualificationResource < ApplicationResource
  primary_endpoint "qualifications", [:index, :show, :create, :destroy]

  self.acceptable_scopes += %w[qualifications]
  self.readable_class = JsonApi::QualificationAbility

  with_options filterable: false, sortable: false do
    attribute :person_id, :integer, filterable: true
    attribute :qualification_kind_id, :integer, filterable: true
    attribute :start_at, :date
    attribute :finish_at, :date
    attribute :qualified_at, :date
    attribute :origin, :string
  end

  belongs_to :person
  belongs_to :qualification_kind
end
