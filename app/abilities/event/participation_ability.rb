# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
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
    permission(:any).may(:show_full, :update).for_participations_full_events
    permission(:any).may(:destroy).her_own_if_application_cancelable

    permission(:group_full).
      may(:show, :show_details, :show_full, :print, :create, :update, :destroy).
      in_same_group

    permission(:group_and_below_full).
      may(:show, :show_details, :show_full, :print, :create, :update, :destroy).
      in_same_group_or_below

    permission(:layer_full).
      may(:show, :show_details, :show_full, :print, :update).
      in_same_layer_or_different_prio
    permission(:layer_full).may(:create, :destroy).in_same_layer

    permission(:layer_and_below_full).
      may(:show, :show_details, :show_full, :print, :update).
      in_same_layer_or_below_or_different_prio
    permission(:layer_and_below_full).may(:create, :destroy).in_same_layer

    permission(:approve_applications).may(:show).for_applicant_in_same_layer

    general(:create).at_least_one_group_not_deleted
  end

  def her_own_or_for_leaded_events
    her_own || for_leaded_events
  end

  def her_own_or_for_participations_read_events
    her_own || (event.participations_visible? && participating?) || for_participations_read_events
  end

  def her_own_if_application_possible
    her_own && event.application_possible?
  end

  def her_own_if_application_cancelable
    her_own &&
      event.applications_cancelable? &&
      (!event.application_closing_at? || event.application_closing_at >= Time.zone.today)
  end

  def participating?
    event.participations.map(&:person_id).include? user.id
  end

  private

  def participation
    subject
  end
end
