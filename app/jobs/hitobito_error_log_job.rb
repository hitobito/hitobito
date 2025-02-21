# frozen_string_literal: true

#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HitobitoErrorLogJob < RecurringJob
  def perform_internal
    if error_log_entry_ids.present?
      HitobitoLogMailer.error(error_log_entry_ids, time_period).deliver_later
    end
  end

  def next_run
    # Sets next run to 05:00 of next day
    Time.zone.tomorrow.at_beginning_of_day.change(hour: 5).in_time_zone
  end

  def error_log_entry_ids = HitobitoLogEntry.where(level: "error", created_at: time_period).pluck(:id)

  def time_period = 1.day.ago.change(hour: 5, min: 0, sec: 0)..Time.current.change(hour: 5, min: 0, sec: 0)
end
