#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Examples::LongRunningUserManagedJob < BaseJob
  prepend UserManageableJob

  def perform
    loop do
      Rails.logger.debug "Working..."
      sleep 3
    end
  end
end
