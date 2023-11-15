# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
class People::RolesBaseJob < RecurringJob

  run_every 1.hour

  private

  def with_handled_exception(role)
    yield role
  rescue => e
    notify("#{e.message} - #{role.class}(#{role.id})")
  end

  def reschedule
    run_at = interval.from_now.beginning_of_hour
    enqueue!(run_at: run_at, priority: 5) unless others_scheduled?
  end

  def notify(message)
    Raven.capture_exception(self.class.const_get('Error').new(message))
  end
end
