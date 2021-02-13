# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module EventMacros
  def set_start_finish(event, start_at, finish_at)
    event.dates.clear
    event.dates.build(start_at: start_at, finish_at: finish_at)
    event.save
  end

  def set_start_dates(event, *dates)
    event.dates.clear
    dates.map! { |date| date.class == String ? Time.zone.parse(date) : date }
    dates.each { |date| event.dates.build(start_at: date) }
    event.save
  end
end
