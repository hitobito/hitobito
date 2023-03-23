# encoding: utf-8

#  Copyright (c) 2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Let's make sure we load the logger in dev env even though eager_load is false.
# Otherwise the logger won't subscribe to the background job log notifications.
require_relative './logger' if Rails.env.development?

module BackgroundJobs
  class Logging < Delayed::Plugin
    callbacks do |lifecycle|
      lifecycle.before(:invoke_job) do |job|
        notify(job, 'job_started', started_at: Time.zone.now)
      end

      # after(:invoke_job) gets only called on success
      lifecycle.after(:invoke_job) do |job|
        notify(job, 'job_finished',
               finished_at: Time.zone.now,
               status: 'success',
               payload: job_result(job))
      end

      lifecycle.after(:error) do |_worker, job|
        notify(job, 'job_finished',
               # The attempt count has already been incremented once we reach here,
               # so we must calculate the correct value.
               attempt: job.attempts - 1,
               finished_at: Time.zone.now,
               status: 'error',
               payload: {error: error_message(job)})
      end
    end

    private

    def self.notify(job, event_name, attempt: job.attempts, **attrs, &block)
      return unless enabled?(job) && job_attrs(job).present?

      log_attrs = job_attrs(job).merge(attrs, attempt: attempt)
      ActiveSupport::Notifications.instrument("#{event_name}.background_job", log_attrs, &block)
    end

    def self.enabled?(job)
      job.payload_object.try(:use_background_job_logging)
    end

    def self.job_attrs(job)
      {
        job_id: job.id,
        job_name: job.payload_object.class.name,
        group_id: job.payload_object.try(:group_id)
      }
    end

    def self.job_result(job)
      job.payload_object.try(:log_results)
    end

    def self.error_message(job)
      {
        class: job.error.class.name,
        message: job.error.message,
        backtrace: job.error.backtrace
      }
    end
  end
end
