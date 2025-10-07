# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

class PeopleManagerAbility < AbilityDsl::Base
  on(PeopleManager) do
    class_side(:index).everybody
    permission(:any).may(:new_managed, :new_manager).everybody
    permission(:any).may(:create_managed, :destroy_managed).if_can_change_managed
    permission(:any).may(:create_manager, :destroy_manager).if_can_change_manager
    permission(:any).may(:show).for_leaded_events_or_readable_manageds
  end

  def if_can_change_manager
    can?(:change_managers, managed) || creating_new_managed_person?
  end

  def if_can_change_managed
    can?(:update, subject.manager)
  end

  def for_leaded_events_or_readable_manageds
    for_leaded_events || can?(:show, managed)
  end

  def for_leaded_events
    leaded_event_ids = user_context.events_with_permission(:event_full)
    managed&.event_participations&.exists?(event_id: leaded_event_ids)
  end

  private

  def managed
    subject.managed
  end

  def creating_new_managed_person?
    managed&.new_record? &&
      FeatureGate.enabled?("people.people_managers.self_service_managed_creation")
  end

  def can?(action, person)
    ability.can?(action, person)
  end

  def ability
    @ability ||= Ability.new(user)
  end
end
