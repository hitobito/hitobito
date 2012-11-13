class BaseJob
  
  def perform
    # override in subclass
  end
  
  def enqueue!
    Delayed::Job.enqueue self
  end
  
  def error(job, exception)
    Rails.logger.error(exception.message)
    Rails.logger.error(exception.backtrace.join("\n"))
    Airbrake.notify(exception)
  end
end