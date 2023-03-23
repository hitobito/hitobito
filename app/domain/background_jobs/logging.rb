require_relative 'logger'

module BackgroundJobs
  module Logging
    extend ActiveSupport::Concern

    included do |base|
      base.prepend DJHooksWrapper
    end

    module DJHooksWrapper
      def before(job)
        @job_instance = job

        super if defined? super
      end

      def perform
        background_job_log_instrument("job_started.background_job", started_at: Time.zone.now)
        background_job_log_instrument("job_perform.background_job") do
          super
        end
      end

      def after(_job)
        background_job_log_instrument(
          "job_finished.background_job",
          finished_at: Time.zone.now,
          payload: log_results
        )

        super if defined? super
      end

      def success(_job)
        background_job_log_instrument("job_success.background_job")

        super if defined? super
      end

      def error(_job, exception)
        error = ["#{exception.class.name}: #{exception.message}", *exception.backtrace].join("\n")
        background_job_log_instrument("job_error.background_job", error: error)

        super if defined? super
      end

      def log_results
        results = super if defined? super
        results || {}
      end

      private

      def background_job_log_instrument(name, **attrs, &block)
        return block&.call unless @job_instance # we can't log the job without knowing its details

        ActiveSupport::Notifications.instrument(name, background_job_log_attrs.merge(attrs), &block)
      end

      def background_job_log_attrs
        {
          job_id: @job_instance.id,
          job_name: self.class.name,
          group_id: try(:group_id),
          attempt: @job_instance.attempts
        }
      end
    end
  end
end
