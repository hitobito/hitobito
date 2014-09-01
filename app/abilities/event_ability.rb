# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Event

  on(Event) do
    permission(:any).may(:read).all
    permission(:any).may(:index_participations).for_event_contacts
    permission(:any).may(:update).for_managed_events
    permission(:any).may(:qualify).for_qualify_event

    permission(:group_full).may(:index_participations, :create, :update, :destroy).in_same_group
    permission(:group_full).may(:manage_courses).if_in_course_group

    permission(:layer_full).may(:index_participations, :update).in_same_layer_or_below
    permission(:layer_full).may(:create, :destroy, :application_market, :qualify).in_same_layer
    permission(:layer_full).may(:manage_courses).if_in_course_layer

    permission(:admin).may(:export).all

    general(:create, :destroy, :application_market, :qualify).at_least_one_group_not_deleted
  end

  def for_qualify_event
    permission_in_event?(:qualify)
  end

  def if_in_course_group
    permission_in_groups?(course_offerers)
  end

  def if_in_course_layer
    permission_in_layers?(course_offerers)
  end

  private

  def event
    subject
  end

  def course_offerers
    @course_offerers ||= Group.course_offerers.pluck(:id)
  end
end
