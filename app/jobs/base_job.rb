# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class BaseJob
  # Define the instance variables defining this job instance.
  # Only these variables will be serizalized when a job is enqueued.
  # Used as airbrake information when the job fails.
  class_attribute :parameters

  # Enable background job logging by setting this to a truthy value.
  # Note: you can also override `#log_results` to include job specific data in the log.
  class_attribute :use_background_job_logging

  # Define a maximum run time of this job.
  # NOTE: this can ONLY be used to set a max_run_time that is lower than Delayed::Worker.max_run_time
  # (see `config/initializers/delayed_job_config.rb`).
  # Otherwise the lock on the job would expire and another worker would start the working on the in progress job.
  class_attribute :max_run_time
  self.max_run_time = 4.hours

  def initialize
    store_locale
  end

  # hook called from DelayedJob
  def perform
    # override in subclass
  end

  def enqueue!(options = {})
    Delayed::Job.enqueue(self, options)
  end

  # hook called from DelayedJob
  def before(delayed_job)
    @delayed_job = delayed_job
  end

  # hook called from DelayedJob
  def error(_job, exception, payload = parameters)
    logger.error(exception.message)
    logger.error(exception.backtrace.join("\n"))
    Airbrake.notify(exception, cgi_data: ENV.to_hash, parameters: payload)
    Raven.capture_exception(exception, logger: "delayed_job")
  end

  def delayed_jobs
    Delayed::Job.where(handler: to_yaml)
  end

  def logger
    Delayed::Worker.logger || Rails.logger
  end

  def store_locale
    @locale = I18n.locale.to_s
  end

  def set_locale
    I18n.locale = @locale || I18n.default_locale
  end

  def parameters
    Array(self.class.parameters).index_with do |p|
      instance_variable_get(:"@#{p}")
    end
  end

  # Only create yaml with the defined parameters.
  def encode_with(coder)
    parameters.each do |key, value|
      coder[key.to_s] = value
    end
  end

  # Override in subclass to report job result.
  # It can return any structure responding to #to_json
  def log_results
    {}
  end

  def handle_termination_signals
    handle_termination_signal('INT') do
      handle_termination_signal('TERM') do
        yield
      end
    end
  end

  def handle_termination_signal(signal)
    @terminate = false
    old_handler = trap(signal) do # dont know if the return value here is actually what we assume
      @terminate = true
      # old_term_handler.call what is old_term_handler
    end
    yield
  ensure
    trap(signal, old_handler) # are these even the correct parameters https://devdocs.io/ruby~3.2/kernel#method-i-trap
  end

  def check_terminated
    raise SignalException if @terminate
  end
end
