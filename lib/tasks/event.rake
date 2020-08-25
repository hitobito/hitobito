# frozen_string_literal: true

#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

namespace :event do
  desc 'Refresh all participant_counts in year (defaults to current year)'
  task :refresh_participant_counts, [:year] => [:environment] do |_, args|
    year = args.fetch(:year, Time.zone.now.year)
    Event.where(created_at: Date.new(year, 1, 1)..Date.new(year, 12, 31)).find_each do |event|
      event.refresh_participant_counts!
    end
  end
end
