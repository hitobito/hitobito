#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Detects and unlocks jobs whose worker isn't running anymore
# (e.g because it was killed during a deployment).
class WorkerHeartbeatCheckJob < RecurringJob
  run_every Settings.worker_heartbeats.check_job.interval.seconds

  def perform_internal
    Delayed::Heartbeat.delete_workers_with_different_version
    Delayed::Heartbeat.delete_timed_out_workers
  end

  def max_run_time
    10 # Seconds
  end
end
