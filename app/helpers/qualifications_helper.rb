# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module QualificationsHelper

  def format_qualification_kind_validity(kind)
    format_unbounded_value(kind.validity) do |d|
      t("qualifications.in_years", years: d)
    end
  end

  def format_qualification_kind_reactivateable(kind)
    format_unbounded_value(kind.reactivateable, "") do |d|
      t("qualifications.in_years", years: d)
    end
  end

  def format_qualification_finish_at(quali)
    format_unbounded_value(quali.finish_at, "") do |d|
      t("qualifications.valid_until", date: d)
    end
  end

  private

  def format_unbounded_value(value, text = t("qualifications.unlimited"))
    if value.present?
      yield f(value)
    else
      text
    end
  end

end
