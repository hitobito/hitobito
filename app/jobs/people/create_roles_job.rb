# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::CreateRolesJob < People::RolesBaseJob

  run_every 1.hour

  Error = Class.new(StandardError)

  def perform_internal
    future_roles.find_each do |role|
      with_handled_exception(role) do
        role.convert!
      end
    end
  end

  private

  def future_roles
    FutureRole.where('convert_on <= :today', today: Time.zone.today).order(:convert_on)
  end
end
