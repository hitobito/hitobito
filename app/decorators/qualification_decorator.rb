# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class QualificationDecorator < ApplicationDecorator
  decorates :qualification

  def open_training_days
    return unless model.open_training_days

    days = helpers.number_to_condensed(model.open_training_days)
    title = open_training_days_title(days)
    icon = helpers.icon(:'info-circle', class: 'p-1', title: title)
    helpers.content_tag(:span, safe_join([content_tag(:span, days), icon]))
  end

  private

  def open_training_days_title(days)
    if model.active? && model.finish_at
      translate(:open_training_days_active, days: days, finish_at: I18n.l(model.finish_at))
    elsif model.reactivateable? && model.reactivateable_until
      translate(:open_training_days_reactivatable,
                days: days,
                reactivateable_until: I18n.l(model.reactivateable_until))
    end
  end
end
