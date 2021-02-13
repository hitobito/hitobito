#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SessionsCleanerJob < RecurringJob
  run_every 24.hours

  def perform_internal
    Session.outdated.delete_all
  end
end
