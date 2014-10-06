# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Event
  include AbilityDsl::Constraints::Event::Participation

  on(Event::Participation) do
    permission(:any).may(:show).her_own_or_for_participations_read_events
    permission(:any).may(:show_details, :print).her_own_or_for_participations_full_events
    permission(:any).may(:create).her_own_if_application_possible
    permission(:any).may(:update).for_participations_full_events

    permission(:group_full).
      may(:show, :show_details, :print, :create, :update, :destroy).
      in_same_group

    permission(:layer_full).
      may(:show, :show_details, :print, :update).
      in_same_layer_or_different_prio
    permission(:layer_full).may(:create, :destroy).in_same_layer

    permission(:layer_and_below_full).
      may(:show, :show_details, :print, :update).
      in_same_layer_or_below_or_different_prio
    permission(:layer_and_below_full).may(:create, :destroy).in_same_layer

    permission(:approve_applications).may(:show).for_applicant_in_same_layer

    general(:create).at_least_one_group_not_deleted
  end

  def her_own_or_for_leaded_events
    her_own || for_leaded_events
  end

  def her_own_or_for_participations_read_events
    her_own || for_participations_read_events
  end

  def her_own_or_for_participations_full_events
    her_own || for_participations_full_events
  end

  def her_own_if_application_possible
    her_own && event.application_possible?
  end

  def in_same_layer_or_different_prio
    in_same_layer || different_prio
  end

  def in_same_layer_or_below_or_different_prio
    in_same_layer_or_below || different_prio
  end

  private

  def participation
    subject
  end

  def different_prio
    return false if participation.active? || !participation.application_id?

    # This is a bit more than really needed, to restrict further we would
    # need the actual course the participation should be displayed for,
    # which we do not have.
    appl = participation.application
    (appl.waiting_list? || appl.priority_2_id? || appl.priority_3_id?) &&
    permission_in_layers?(course_offerers)
  end

  def course_offerers
    @course_offerers ||= Group.course_offerers.pluck(:id)
  end
end
