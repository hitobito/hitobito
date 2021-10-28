# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Event
  include AbilityDsl::Constraints::Event::Invitation

  on(Event) do
    class_side(:list_available, :typeahead).if_any_role

    permission(:any).may(:show).if_globally_visible_or_participating

    permission(:any).may(:index_participations)
                    .for_participations_read_events_or_visible_fellow_participants
    permission(:any).may(:update).for_leaded_events
    permission(:any).may(:qualify, :qualifications_read).for_qualify_event

    permission(:group_full).may(:index_participations, :show).in_same_group
    permission(:group_full).may(:index_invitations).in_same_group_and_invitations_supported
    permission(:group_full).may(:create, :update, :destroy).in_same_group_if_active

    permission(:group_and_below_full).may(:index_participations, :show)
                                     .in_same_group_or_below
    permission(:group_and_below_full).may(:index_invitations)
                                     .in_same_group_or_below_and_invitations_supported
    permission(:group_and_below_full).may(:create, :update, :destroy)
                                     .in_same_group_or_below_if_active

    permission(:layer_full).may(:index_participations,
                                :qualifications_read, :show)
                           .in_same_layer
    permission(:layer_full).may(:index_invitations).in_same_layer
    permission(:layer_full).may(:update, :create, :destroy, :application_market, :qualify)
                           .in_same_layer_if_active

    permission(:layer_and_below_full).may(:index_participations, :show)
                                     .in_same_layer_or_below
    permission(:layer_and_below_full).may(:index_participations, :index_invitations, :show)
                                     .in_same_layer_or_below_and_invitations_supported
    permission(:layer_and_below_full).may(:update).in_same_layer_or_below_if_active
    permission(:layer_and_below_full).may(:qualifications_read).in_same_layer
    permission(:layer_and_below_full).may(:create, :destroy, :application_market, :qualify)
                                     .in_same_layer_if_active

    general(:create, :destroy, :application_market, :qualify, :qualifications_read)
      .at_least_one_group_not_deleted
  end

  on(Event::Course) do
    class_side(:list_available).everybody
    class_side(:list_all).if_full_permission_in_course_layer
    class_side(:export_list).if_layer_and_below_full_on_root
  end

  def if_globally_visible_or_participating
    subject.globally_visible? ||
      subject.token_accessible?(user.shared_access_token) ||
      participant? ||
      subject.external_applications?
  end

  def for_qualify_event
    permission_in_event?(:qualify)
  end

  def if_in_course_group
    permission_in_groups?(course_offerers)
  end

  def if_full_permission_in_course_layer
    contains_any?(user_context.permission_layer_ids(:layer_full) +
                  user_context.permission_layer_ids(:layer_and_below_full),
                  course_offerers)
  end

  def if_layer_and_below_full_on_root
    user_context.permission_layer_ids(:layer_and_below_full).include?(Group.root.id)
  end

  def for_participations_read_events_or_visible_fellow_participants
    for_participations_read_events || (event.participations_visible? && participant?)
  end

  private

  def event
    subject
  end

  def course_offerers
    @course_offerers ||= Group.course_offerers.pluck(:id)
  end

  def participant?
    user.event_participations.
      select(&:active?).
      select { |p| p.event == event }.
      flat_map(&:roles).
      any? { |r| r.is_a?(Event::Role::Participant) }
  end

end
