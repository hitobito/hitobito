# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
class People::CreateRolesJob < RecurringJob

  run_every 15.minutes

  Error = Class.new(StandardError)

  def perform
    future_roles.find_each { |role| convert(role) }
  end

  private

  def future_roles
    FutureRole.where('convert_on <= :today', today: Time.zone.today).order(:convert_on)
  end

  def convert(role)
    role.convert!
  rescue => e
    message = "#{e.message} - FutureRole(#{role.id})"
    role.update!(label: message)
    notify(message)
  end

  def notify(message)
    Raven.capture_exception(Error.new(message))
  end
end
