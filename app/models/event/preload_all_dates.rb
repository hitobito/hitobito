# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Event::PreloadAllDates

  def self.extended(base)
    base.do_preload_all_dates
  end

  def self.for(records)
    records = Array(records)

    # preload dates
    ActiveRecord::Associations::Preloader.new.
      preload(records, [:dates])

    records
  end

  def do_preload_all_dates
    @do_preload_all_dates = true
  end

  private

  def exec_queries
    records = super

    Event::PreloadAllDates.for(records) if @do_preload_all_dates

    records
  end
end
