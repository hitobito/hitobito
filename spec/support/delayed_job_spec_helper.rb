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
    delayed_job_spec_worker.run(job_instance)
  end

  def delayed_job_spec_worker(max_run_time: 10.seconds, max_attempts: 2)
    worker = Delayed::Worker.new
    worker.max_run_time = max_run_time
    worker.max_attempts = max_attempts
    worker
  end
end
