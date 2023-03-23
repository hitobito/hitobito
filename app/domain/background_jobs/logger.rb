module BackgroundJobs
  class Logger < ActiveSupport::Subscriber
    attach_to :background_job

    def job_started(message)
      log(message, status: 'started')
    end

    def job_finished(message)
      log(message, status: 'finished')
    end

    private

    def log(message, **opts)
      attrs = message.payload.with_indifferent_access
                     .slice(*BackgroundJobLogEntry.column_names)
                     .merge(updated_at: Time.zone.now)
                     .reverse_merge(**opts)
      BackgroundJobLogEntry.upsert(**attrs)
    rescue
      # Let's not fail the job because of a logging problem, but at least report the error.
      ::Raven.capture_exception($!)
    end
  end
end
