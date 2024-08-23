#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Rails.application.reloader.to_prepare do
  Delayed::Worker.max_attempts = 10
  # Maximum run time of a job. This can only be configured lower for specific jobs, but not higher.
  # Therefore we use a high value here to allow for exceptionally long running jobs.
  # By default, BaseJobs have a shorter max_run_time configured.
  Delayed::Worker.max_run_time = 24.hours
  Delayed::Worker.plugins << BackgroundJobs::Logging
end

# ActiveJob will reload codes if necessary. DelayedJob consumes CPU and memory for reloading on every 5 secs.
# TODO: https://github.com/collectiveidea/delayed_job/issues/776#issuecomment-307161178
Delayed::Worker.instance_exec do
  def self.reload_app?
    false
  end
end
