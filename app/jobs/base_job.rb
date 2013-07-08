class BaseJob

  # Define the instance variables defining this job instance.
  # Used as airbrake information when the job fails.
  class_attribute :parameters

  def perform
    # override in subclass
  end

  def enqueue!(options = {})
    Delayed::Job.enqueue(self, options)
  end

  def error(job, exception, payload = parameters)
    logger.error(exception.message)
    logger.error(exception.backtrace.join("\n"))
    Airbrake.notify(exception, cgi_data: ENV, parameters: payload)
  end

  def delayed_jobs
    Delayed::Job.where(handler: self.to_yaml)
  end

  def logger
    Delayed::Worker.logger || Rails.logger
  end

  def parameters
    Array(self.class.parameters).each_with_object({}) do |p, hash|
      hash[p] = instance_variable_get(:"@#{p}")
    end
  end

end