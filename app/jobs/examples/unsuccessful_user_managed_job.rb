#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Examples::UnsuccessfulUserManagedJob < BaseJob
  prepend UserManageableJob

  def perform
    Rails.logger.debug "Working..."
    raise "Something went wrong during job execution"
  end
end
