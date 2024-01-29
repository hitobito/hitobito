# frozen_string_literal: true

#  Copyright (c) 2022-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :delayed_job do
  desc 'Schedule Background-Jobs'
  task schedule: [:environment, :'db:abort_if_pending_migrations'] do
    next if Rails.env.test?

    JobManager.new.schedule
  end

  desc 'Clear all scheduled Background-Jobs'
  task clear: [:environment, :'db:abort_if_pending_migrations'] do
    JobManager.new.clear
  end

  desc 'Check if all expected jobs are scheduled'
  task check: [:environment, :'db:abort_if_pending_migrations'] do
    exit false unless JobManager.new.check
  end
end
