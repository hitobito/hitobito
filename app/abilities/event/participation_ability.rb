# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Event
  include AbilityDsl::Constraints::Event::Participation

  on(Event::Participation) do # rubocop:disable Metrics/BlockLength
    permission(:any).may(:show).her_own_or_manager_or_for_participations_read_events
    permission(:any).may(:show_details, :print)
      .her_own_or_manager_or_for_participations_read_details_events
    permission(:any).may(:create).her_own_if_application_possible
    permission(:any).may(:show_full, :update, :send_mails).for_participations_full_events
    permission(:any).may(:destroy).her_own_if_application_cancelable

    # Participations listed via API
    permission(:any).may(:index).her_own_or_guests_or_manager_or_for_participations_read_events
    permission(:group_read).may(:index).in_same_group
    permission(:group_and_below_read).may(:index).in_same_group_or_below
    permission(:layer_read).may(:index).in_same_layer_or_pending_application
    permission(:layer_and_below_read).may(:index).in_same_layer_or_below_or_pending_application

    permission(:group_full)
      .may(:show, :show_details, :show_full, :print)
      .in_same_group

    permission(:group_full)
      .may(:send_mails, :create, :update, :destroy)
      .in_same_group_if_active

    permission(:group_and_below_full)
      .may(:show, :show_details, :show_full, :print)
      .in_same_group_or_below

    permission(:group_and_below_full)
      .may(:send_mails, :create, :update, :destroy)
      .in_same_group_or_below_if_active

    permission(:layer_full)
      .may(:show, :show_details, :show_full, :print, :update)
      .in_same_layer_or_different_prio

    permission(:layer_full)
      .may(:create, :destroy, :send_mails)
      .in_same_layer_if_active

    permission(:layer_and_below_full)
      .may(:show, :show_details, :show_full, :print, :update)
      .in_same_layer_or_below_or_different_prio

    permission(:layer_and_below_full)
      .may(:create, :destroy, :send_mails)
      .in_same_layer_or_below_if_active

    permission(:approve_applications).may(:show).for_applicant_in_same_layer

    general(:create).at_least_one_group_not_deleted

    for_self_or_manageds do
      permission(:any).may(:create).her_own_if_application_possible
      permission(:any).may(:destroy).her_own_if_application_cancelable
      general(:create).at_least_one_group_not_deleted
    end
  end

  def her_own_or_for_leaded_events
    any_of(her_own, for_leaded_events)
  end

  def her_own_or_for_participations_read_events
    any_of(her_own, visible_fellow_participations, for_participations_read_events)
  end

  def her_own_if_application_possible
    all_of(her_own, event_condition(application_possible), participant_can_show_event)
  end

  def her_own_if_application_cancelable
    all_of(her_own,
      event_condition(applications_cancelable: true,
        application_closing_at: [nil, Time.zone.today..]))
  end

  def her_own_or_manager_or_for_participations_read_events
    any_of(her_own_or_for_participations_read_events, manager)
  end

  def her_own_or_manager_or_for_participations_read_details_events
    any_of(her_own_or_for_participations_read_details_events, manager)
  end

  def her_own_or_manager_or_for_participations_full_events
    any_of(her_own_or_for_participations_full_events, manager)
  end

  def her_own_or_guests_or_manager_or_for_participations_read_events
    any_of(her_own_or_manager_or_for_participations_read_events, guests, for_leaded_events)
  end

  def in_same_layer_or_pending_application
    any_of(in_same_layer, pending_application_in_course_offerer)
  end

  def in_same_layer_or_below_or_pending_application
    any_of(in_same_layer_or_below, pending_application_in_course_offerer)
  end

  def participating
    event_ids = user_context.participations.map(&:event_id)
    {event_id: event_ids} if event_ids.present?
  end
  alias_method :if_participating, :participating

  def participant_can_show_event
    {event_id: accessible_ids(Event, :show, AbilityWithoutManagerAbilities)}
  end

  private

  def visible_fellow_participations
    all_of(participating, event_condition(participations_visible: true))
  end

  def guests
    return if user_context.participations.blank?

    guests = Event::Guest.where(main_applicant_id: user_context.participations.map(&:id))
    {participant_type: Event::Guest.sti_name, participant_id: guests.select(:id)}
  end

  def manager
    managed_ids = user.manageds.map(&:id)
    {participant_type: Person.sti_name, participant_id: managed_ids} if managed_ids.present?
  end

  def application_possible
    all_of({application_opening_at: [nil, ..Time.zone.today],
            application_closing_at: [nil, Time.zone.today..]},
      any_of({id: Event.with_places_available.select(:id)},
        {type: sti_names(waiting_list_event_types), waiting_list: true}))
  end

  def waiting_list_event_types
    Event.all_types.select { |type| type.supports_applications && type.attr_used?(:waiting_list) }
  end

  def pending_application_in_course_offerer
    different_prio if contains_any?(user_layer_ids, user_context.course_offerers)
  end
end
