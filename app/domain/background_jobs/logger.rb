# encoding: utf-8

#  Copyright (c) 2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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
                     .reverse_merge(**opts)
      BackgroundJobLogEntry.upsert(attrs)
    rescue
      # Let's not fail the job because of a logging problem, but at least report the error.
      ::Raven.capture_exception($!)
    end
  end
end
