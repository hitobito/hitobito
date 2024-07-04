# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class QualificationDecorator < ApplicationDecorator
  decorates :qualification

  def open_training_days_info
    return if !model.open_training_days && !model.reactivateable_until

    infos = [icon]
    infos.unshift(content_tag(:span, formatted_days, class: "mr-2")) if model.open_training_days
    helpers.content_tag(:span, safe_join(infos))
  end

  private

  def icon
    helpers.icon(:"info-circle", title: tooltip)
  end

  def tooltip
    if model.active? && model.finish_at
      translate(:open_training_days_active,
        days: formatted_days,
        finish_at: I18n.l(model.finish_at))
    elsif model.reactivateable_until
      if model.reactivateable?
        translate(:open_training_days_reactivatable,
          days: formatted_days,
          reactivateable_until: I18n.l(model.reactivateable_until))
      else
        translate(:open_training_days_no_longer_reactivatable,
          reactivateable_until: I18n.l(model.reactivateable_until))
      end
    end
  end

  def formatted_days
    helpers.number_to_condensed(model.open_training_days)
  end
end
