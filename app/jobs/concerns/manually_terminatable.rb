#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ManuallyTerminatable
  def before(delayed_job)
    super
    check_status
  end

  def perform
    super
  rescue JobManuallyTerminated
    Rails.logger.debug "Termination message from Base Job"
  ensure
    @status_check_thread.exit if @status_check_thread.alive?
  end

  private

  def check_status
    @status_check_thread = Thread.new do
      loop do
        if @delayed_job.reload.status_control == "terminate"
          Thread.main.raise(JobManuallyTerminated.new)
        end
        sleep 3
      end
    end
  end
end
