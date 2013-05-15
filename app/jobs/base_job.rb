class BaseJob

  def perform
    # override in subclass
  end

  def enqueue!(options = {})
    Delayed::Job.enqueue(self, options)
  end

  def error(job, exception, payload = {})
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
end