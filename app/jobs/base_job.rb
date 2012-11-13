class BaseJob
  
  def perform
    # override in subclass
  end
  
  def error(job, exception)
    Airbrake.notify(exception)
  end
end