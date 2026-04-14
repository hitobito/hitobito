#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module DelayedJobSpecHelper
  def enqueue_and_run_job(payload_object)
    payload_object.enqueue!.tap do |job_instance|
      run_enqueued_job(job_instance)
    end
  end

  def run_enqueued_job(job_instance)
    worker = Delayed::Worker.new
    worker.max_run_time = 10.seconds
    worker.max_attempts = 2
    worker.run(job_instance)
  end
end
