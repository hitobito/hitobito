class RecurringJob < BaseJob
  
  class << self
    def run_every(seconds)
      @interval = seconds
    end
    
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
  
  def schedule
    enqueue!(priority: 5) unless scheduled?
  end

  def scheduled?
    delayed_jobs.present?
  end
  
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
    next_run = interval.from_now
    if job = delayed_jobs.first
      begin
        next_run = job.run_at + interval
      end while next_run < Time.zone.now
    end
    next_run
  end
end