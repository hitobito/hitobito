# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Event

  on(Event) do
    class_side(:list_available, :typeahead).everybody

    permission(:any).may(:show).if_globally_visible
    permission(:any).may(:index_participations).
      for_participations_read_events_and_course_participants
    permission(:any).may(:update).for_leaded_events
    permission(:any).may(:qualify, :qualifications_read).for_qualify_event

    permission(:group_full)
      .may(:index_participations, :create, :update, :destroy, :show)
      .in_same_group

    permission(:group_and_below_full).
      may(:index_participations, :create, :update, :destroy, :show).
      in_same_group_or_below

    permission(:layer_full).
      may(:index_participations, :update, :create, :destroy,
          :application_market, :qualify, :qualifications_read, :show).
      in_same_layer

    permission(:layer_and_below_full).
      may(:index_participations, :update, :show).in_same_layer_or_below
    permission(:layer_and_below_full).
      may(:create, :destroy, :application_market, :qualify, :qualifications_read).in_same_layer

    general(:create, :destroy, :application_market, :qualify, :qualifications_read).
      at_least_one_group_not_deleted
  end

  on(Event::Course) do
    class_side(:list_available).everybody
    class_side(:list_all).if_full_permission_in_course_layer
    class_side(:export_list).if_layer_and_below_full_on_root
  end

  def if_globally_visible
    subject.is_a?(Event::Course) || subject.globally_visible?
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

  def for_participations_read_events_and_course_participants
    return for_participations_read_events unless subject.is_a?(::Event::Course)

    for_participations_read_events || participant?
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
