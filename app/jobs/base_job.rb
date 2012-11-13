class BaseJob
  
  def perform
    # override in subclass
  end
  
  def enqueue!
    Delayed::Job.enqueue self
  end
  
  def error(job, exception)
    Airbrake.notify(exception)
  end
end