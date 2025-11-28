# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Event
  include AbilityDsl::Constraints::Event::Participation

  on(Event::Participation) do # rubocop:disable Metrics/BlockLength
    permission(:any).may(:show).her_own_or_for_participations_read_events
    permission(:any).may(:show_details, :print).her_own_or_for_participations_full_events
    permission(:any).may(:create).her_own_if_application_possible
    permission(:any).may(:show_full, :update).for_participations_full_events
    permission(:any).may(:destroy).her_own_if_application_cancelable

    permission(:group_full)
      .may(:show, :show_details, :show_full, :print, :create, :update, :destroy)
      .in_same_group

    permission(:group_and_below_full)
      .may(:show, :show_details, :show_full, :print, :create, :update, :destroy)
      .in_same_group_or_below

    permission(:layer_full)
      .may(:show, :show_details, :show_full, :print, :update)
      .in_same_layer_or_different_prio
    permission(:layer_full).may(:create, :destroy).in_same_layer

    permission(:layer_and_below_full)
      .may(:show, :show_details, :show_full, :print, :update)
      .in_same_layer_or_below_or_different_prio
    permission(:layer_and_below_full).may(:create, :destroy).in_same_layer

    permission(:approve_applications).may(:show).for_applicant_in_same_layer

    general(:create).at_least_one_group_not_deleted

    permission(:group_full).may(:mail_confirmation).in_same_group_if_active
    permission(:group_and_below_full).may(:mail_confirmation).in_same_group_or_below_if_active
    permission(:layer_full).may(:mail_confirmation).in_same_layer_if_active
    permission(:layer_and_below_full).may(:mail_confirmation).in_same_layer_if_active

    for_self_or_manageds do
      permission(:any).may(:create).her_own_if_application_possible
      permission(:any).may(:destroy).her_own_if_application_cancelable
      general(:create).at_least_one_group_not_deleted
    end
    # abilities which managers inherit from their managed children
    permission(:any).may(:show).her_own_or_manager_or_for_participations_read_events
    permission(:any).may(:show_details, :print)
      .her_own_or_manager_or_for_participations_full_events
  end

  on(Event::Guest) do
    permission(:any).may(:create).if_participating
  end

  def her_own_or_for_leaded_events
    her_own || for_leaded_events
  end

  def her_own_or_for_participations_read_events
    her_own || (event.participations_visible? && participating) || for_participations_read_events
  end

  def her_own_if_application_possible
    her_own && event.application_possible? && participant_can_show_event?
  end

  def her_own_if_application_cancelable
    her_own &&
      event.applications_cancelable? &&
      (!event.application_closing_at? || event.application_closing_at >= Time.zone.today)
  end

  def her_own_or_manager_or_for_participations_read_events
    her_own_or_for_participations_read_events || manager
  end

  def her_own_or_manager_or_for_participations_full_events
    her_own_or_for_participations_full_events || manager
  end

  def participating
    user_context.participations.any? { |p| p.event_id == event.id }
  end
  alias_method :if_participating, :participating

  def participant_can_show_event?
    participation.person &&
      AbilityWithoutManagerAbilities.new(person).can?(:show, event)
  end

  private

  def participation
    subject
  end

  def manager
    manager_ids = person&.managers&.pluck(:id) || []
    contains_any?([user.id], manager_ids)
  end

  def person
    participation.person
  end
end
