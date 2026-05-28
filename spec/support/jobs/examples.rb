module Examples
  class ObservableJobWithProgress < BaseJob
    prepend ObservableJob

    self.reports_progress = true

    def perform
      5.times do |i|
        Rails.logger.debug "Working..."
        report_progress!(i, 5)
      end
    end
  end

  class UnsuccessfulObservableJob < BaseJob
    prepend ObservableJob

    def perform
      Rails.logger.debug "Working..."
      raise "Test exception: Something went wrong during job execution"
    end
  end

  class SuccessfulObservableJob < BaseJob
    prepend ObservableJob

    def perform
      Rails.logger.debug "Working..."
    end
  end

  class ObservableParentJob < BaseJob
    prepend ObservableJob

    def perform
      3.times do
        child_job = ObservableChildJob.new
        child_job.user_id = @user_id
        child_job.enqueue!
      end
    end
  end

  class ObservableChildJob < BaseJob
    prepend ObservableJob

    def perform
      Rails.logger.debug "Working..."
    end
  end
end
