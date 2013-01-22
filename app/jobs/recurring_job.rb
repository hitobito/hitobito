# A job that is run regularly after a certain interval.
class RecurringJob < BaseJob
  
  class << self
    # Define the interval to run this job. Default is 15 minutes.
    def run_every(seconds)
      @interval = seconds
    end
    
    # The interval to run this job.
    def interval
      @interval
    end
  end
  
  run_every 15.minutes
  
  
  def perform
    perform_internal
  ensure
    reschedule
  end
  
  # Enqueue delayed job if it is not enqueued already
  def schedule
    enqueue!(priority: 5) unless scheduled?
  end

  # Is this job enqueued in delayed job?
  def scheduled?
    delayed_jobs.present?
  end
  
  # The interval to run this job.
  def interval
    self.class.interval
  end
  
  # set max attempts to 1 to avoid rescheduling by delayed job
  def max_attempts
    1
  end
  
  private
  
  def reschedule
    enqueue!(run_at: next_run, priority: 5)
  end
  
  def next_run
    if job = delayed_jobs.first
      [Time.zone.now, job.run_at + interval].max
    else
      interval.from_now
    end
  end
end