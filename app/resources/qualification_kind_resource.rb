# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class QualificationKindResource < ApplicationResource
  with_options writable: false, filterable: false, sortable: false do
    attribute :label, :string
    attribute :description, :string
    attribute :validity, :integer
    attribute :reactivateable, :integer
    attribute :required_training_days, :integer
  end

  # has no endpoint, only included via qualifications
  def base_scope = QualificationKind.includes(:translations)
end
