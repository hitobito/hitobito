# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Event

  on(Event) do
    class_side(:list_available).everybody

    permission(:any).may(:show).all
    permission(:any).may(:index_participations).for_participations_read_events
    permission(:any).may(:update).for_leaded_events
    permission(:any).may(:qualify).for_qualify_event

    permission(:group_full).may(:index_participations, :create, :update, :destroy).in_same_group

    permission(:layer_full).may(:index_participations, :update).in_same_layer
    permission(:layer_full).may(:create, :destroy, :application_market, :qualify).in_same_layer

    permission(:layer_and_below_full).
      may(:index_participations, :update).in_same_layer_or_below
    permission(:layer_and_below_full).
      may(:create, :destroy, :application_market, :qualify).in_same_layer

    general(:create, :destroy, :application_market, :qualify).at_least_one_group_not_deleted
  end

  on(Event::Course) do
    class_side(:list_available).everybody
    class_side(:list_all).if_full_permission_in_course_layer
    class_side(:export_list).if_admin
  end

  def for_qualify_event
    permission_in_event?(:qualify)
  end

  def if_in_course_group
    permission_in_groups?(course_offerers)
  end

  def if_full_permission_in_course_layer
    contains_any?(user_context.layers_full + user_context.layers_and_below_full, course_offerers)
  end

  private

  def event
    subject
  end

  def course_offerers
    @course_offerers ||= Group.course_offerers.pluck(:id)
  end
end
