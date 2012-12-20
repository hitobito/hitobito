class BaseJob
  
  def perform
    # override in subclass
  end
  
  def enqueue!(options = {})
    Delayed::Job.enqueue(self, options)
  end
  
  def error(job, exception)
    Rails.logger.error(exception.message)
    Rails.logger.error(exception.backtrace.join("\n"))
    Airbrake.notify(exception)
  end
  
  def delayed_jobs
    Delayed::Job.where(handler: self.to_yaml)
  end
end