# frozen_string_literal: true

#  Copyright (c) 2023-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::CleanupFinder
  def run
    people_to_cleanup_scope.distinct
  end

  private

  def people_to_cleanup_scope
    base_scope
      .joins("LEFT JOIN roles ON roles.person_id = people.id")
      .then { |scope| without_any_roles_or_with_roles_outside_cutoff(scope) }
      .then { |scope| without_participating_in_future_events(scope) }
      .then { |scope| with_current_sign_in_at_outside_cutoff(scope) }
  end

  def base_scope
    Person.where.not(id: Person.root.id)
      .where(minimized_at: nil)
      .order(:id)
  end

  def no_roles_exist
    Role
      .with_inactive.where("roles.person_id = people.id")
      .arel.exists.not
  end

  def no_active_roles_exist
    Role
      .active.where("roles.person_id = people.id")
      .arel.exists.not
  end

  def without_any_roles_or_with_roles_outside_cutoff(scope)
    scope.where(no_roles_exist).or(with_roles_outside_cutoff(scope).where(no_active_roles_exist))
  end

  def with_roles_outside_cutoff(scope)
    roles_outside_cutoff = Role.with_inactive
      .having("MAX(roles.end_on) <= ?", last_role_ended_on)
      .group("person_id")
      .select(:person_id)

    scope.where("people.id IN (#{roles_outside_cutoff.to_sql})")
  end

  def without_participating_in_future_events(scope)
    scope.where(not_participating_in_future_events)
  end

  def with_current_sign_in_at_outside_cutoff(scope)
    scope.where("people.current_sign_in_at <= ? OR people.current_sign_in_at IS NULL",
      current_sign_in_at)
  end

  def last_role_ended_on
    Settings.people.cleanup_cutoff_duration.regarding_roles.months.ago.to_date
  end

  def not_participating_in_future_events
    Event
      .joins(:dates, :participations)
      .where("event_dates.start_at > :now OR event_dates.finish_at > :now", now: Time.zone.now)
      .where("event_participations.participant_id = people.id")
      .where(event_participations: {participant_type: Person.sti_name})
      .select("*")
      .arel.exists.not
  end

  def current_sign_in_at
    Settings.people.cleanup_cutoff_duration.regarding_current_sign_in_at.months.ago
  end
end
