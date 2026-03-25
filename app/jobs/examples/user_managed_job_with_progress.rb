#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Examples::UserManagedJobWithProgress < BaseJob
  prepend UserManageableJob

  self.reports_progress = true

  def perform
    5.times do |i|
      Rails.logger.debug "Working..."
      report_progress(i, 5)
    end
  end
end
