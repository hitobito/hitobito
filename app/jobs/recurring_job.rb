# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# A job that is run regularly after a certain interval.
class RecurringJob < BaseJob

  # The interval to run this job.
  class_attribute :interval

  class << self
    # Define the interval to run this job. Default is 15 minutes.
    def run_every(seconds)
      self.interval = seconds
    end
  end

  run_every 15.minutes


  def perform
    I18n.locale = I18n.default_locale
    perform_internal
  ensure
    reschedule
  end

  # Enqueue delayed job if it is not enqueued already
  def schedule
    Delayed::Job.transaction do
      reschedule unless scheduled?
    end
  end

  # Is this job enqueued in delayed job?
  def scheduled?
    delayed_jobs.present?
  end

  # set max attempts to 1 to avoid rescheduling by delayed job
  def max_attempts
    1
  end

  private

  def reschedule
    enqueue!(run_at: next_run, priority: 5)
  end

  def next_run
    job = delayed_jobs.first
    if job
      [Time.zone.now, job.run_at + interval].max
    else
      interval.from_now
    end
  end
end
