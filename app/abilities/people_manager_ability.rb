# frozen_string_literal: true

#  Copyright (c) 2024-2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

class PeopleManagerAbility < AbilityDsl::Base
  on(PeopleManager) do
    class_side(:index).everybody
    permission(:any).may(:new_managed, :new_manager).everybody
    permission(:any).may(:create_managed).if_can_change_managed
    permission(:any).may(:destroy_managed).if_can_destroy_managed
    permission(:any).may(:create_manager).if_can_create_manager
    permission(:any).may(:destroy_manager).if_can_change_manager
    permission(:any).may(:show).for_leaded_events_or_readable_manageds
  end

  def if_can_change_managed
    any_of(all_of(managed_accessible(:update_email), if_can_change_manager),
      creating_new_managed_person)
  end

  def if_can_destroy_managed
    managed_accessible(:update_email)
  end

  def if_can_create_manager
    any_of(all_of(managed_accessible(:update_email), if_can_change_manager),
      creating_new_managed_person)
  end

  def if_can_change_manager
    managed_accessible(:change_managers)
  end

  def for_leaded_events_or_readable_manageds
    any_of(for_leaded_events, managed_accessible(:show))
  end

  def for_leaded_events
    leaded_event_ids = user_context.events_with_permission(:event_full)
    {managed: {event_participations: {event_id: leaded_event_ids}}} if leaded_event_ids.present?
  end

  private

  def managed_accessible(action)
    {managed_id: accessible_ids(Person, action)}
  end

  def creating_new_managed_person
    return unless FeatureGate.enabled?("people.people_managers.self_service_managed_creation")

    {managed_id: nil}
  end
end
