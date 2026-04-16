module Examples
  class UserManagedJobWithProgress < BaseJob
    prepend UserManageableJob

    self.reports_progress = true

    def perform
      5.times do |i|
        Rails.logger.debug "Working..."
        report_progress!(i, 5)
      end
    end
  end

  class UnsuccessfulUserManagedJob < BaseJob
    prepend UserManageableJob

    def perform
      Rails.logger.debug "Working..."
      raise "Something went wrong during job execution"
    end
  end

  class SuccessfulUserManagedJob < BaseJob
    prepend UserManageableJob

    self.job_name = "Custom job name"

    def perform
      Rails.logger.debug "Working..."
    end
  end

  class LongRunningUserManagedJob < BaseJob
    prepend UserManageableJob

    def perform
      loop do
        Rails.logger.debug "Working..."
      end
    end
  end
end
