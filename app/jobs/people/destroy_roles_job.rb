# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
class People::DestroyRolesJob < RecurringJob
  run_every 15.minutes

  def perform_internal
    roles = Role.where('delete_on <= ?', Time.zone.today)
    roles.find_each(&:destroy!)
  end
end
