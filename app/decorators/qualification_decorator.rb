# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class QualificationDecorator < ApplicationDecorator
  decorates :qualification

  delegate :open_training_days, to: :model

  def open_training_days_info
    return if [open_training_days, tooltip].none?(&:present?)

    infos = [icon(tooltip)]
    infos.unshift(content_tag(:span, formatted_days)) if open_training_days&.positive?
    helpers.content_tag(:span, safe_join(infos))
  end

  private

  def icon(tooltip)
    helpers.icon(:'info-circle', class: 'p-1', title: tooltip)
  end

  def tooltip
    @tooltip ||=
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
                    days: formatted_days,
                    reactivateable_until: I18n.l(model.reactivateable_until))
        end
      end
  end

  def formatted_days
    value = model.open_training_days
    value = model.qualification_kind.required_training_days if value&.zero?
    helpers.number_to_condensed(value)
  end
end
