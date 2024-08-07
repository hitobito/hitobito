# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
class People::DestroyRolesJob < People::RolesBaseJob
  run_every 1.hour

  Error = Class.new(StandardError)

  def perform_internal
    obsolete_roles.find_each do |role|
      with_handled_exception(role) do
        role.destroy!
      end
    end
  end

  private

  def obsolete_roles
    Role.where(delete_on: ..Time.zone.today).order(:delete_on)
  end
end
