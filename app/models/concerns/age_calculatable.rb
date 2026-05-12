# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AgeCalculatable
  extend ActiveSupport::Concern

  def years(comparison = Time.zone.now.to_date)
    return unless respond_to?(:birthday) && birthday.present?

    birthday_has_passed =
      (comparison.month > birthday.month) ||
      (comparison.month == birthday.month && comparison.day >= birthday.day)

    comparison.year - birthday.year - (birthday_has_passed ? 0 : 1)
  end
end
