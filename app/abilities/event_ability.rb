# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Event
  include AbilityDsl::Constraints::Event::Invitation

  on(Event) do # rubocop:todo Metrics/BlockLength
    class_side(:typeahead).if_any_role

    permission(:any).may(:show).in_same_layer_or_public_or_participating
    permission(:any).may(:list_available).in_same_layer_or_public_or_participating_if_any_role
    permission(:layer_and_below_read).may(:list_available).in_same_layer_or_below
    permission(:see_invisible_from_above).may(:list_available).in_same_layer_or_below

    permission(:any)
      .may(:index_participations)
      .for_participations_read_events_or_visible_fellow_participants
    permission(:any)
      .may(:index_full_participations)
      .for_participations_full_events
    permission(:any).may(:update, :create_tags, :assign_tags, :manage_attachments).for_leaded_events
    permission(:any).may(:qualify, :qualifications_read).for_qualify_event

    permission(:group_full)
      .may(:index_participations, :index_full_participations, :show)
      .in_same_group
    permission(:group_full)
      .may(:index_invitations)
      .in_same_group_and_invitations_supported
    permission(:group_full)
      .may(:create, :update, :destroy, :create_tags, :assign_tags, :manage_attachments)
      .in_same_group_if_active

    permission(:group_and_below_full)
      .may(:index_participations, :index_full_participations, :show)
      .in_same_group_or_below
    permission(:group_and_below_full)
      .may(:index_invitations)
      .in_same_group_or_below_and_invitations_supported
    permission(:group_and_below_full)
      .may(:create, :update, :destroy, :create_tags, :assign_tags, :manage_attachments)
      .in_same_group_or_below_if_active

    permission(:layer_full)
      .may(:index_participations, :index_full_participations, :qualifications_read, :show)
      .in_same_layer
    permission(:layer_full).may(:index_invitations).in_same_layer_and_invitations_supported
    permission(:layer_full)
      .may(:update, :create, :destroy, :application_market, :qualify,
        :create_tags, :assign_tags, :manage_attachments)
      .in_same_layer_if_active

    permission(:layer_and_below_full)
      .may(:index_participations, :index_full_participations, :show)
      .in_same_layer_or_below
    permission(:layer_and_below_full)
      .may(:index_invitations)
      .in_same_layer_or_below_and_invitations_supported
    permission(:layer_and_below_full)
      .may(:update, :create_tags, :assign_tags, :manage_attachments)
      .in_same_layer_or_below_if_active
    permission(:layer_and_below_full).may(:qualifications_read).in_same_layer
    permission(:layer_and_below_full)
      .may(:create, :destroy, :application_market, :qualify)
      .in_same_layer_if_active

    general(:create, :destroy, :application_market, :qualify, :qualifications_read)
      .at_least_one_group_not_deleted

    for_self_or_manageds do
      # abilities which managers inherit from their managed children
      permission(:any).may(:list_available).in_same_layer_or_public_or_participating_if_any_role
      permission(:any).may(:show).in_same_layer_or_public_or_participating
    end
  end

  on(Event::Course) do
    # Everybody may open the list of courses, which courses are listed is defined on Event.
    permission(:any).may(:list_available).no_instances
    class_side(:list_all).if_full_permission_in_course_layer
    class_side(:export_list).if_layer_and_below_full_on_root

    for_self_or_manageds do
      # abilities which managers inherit from their managed children
      permission(:any).may(:list_available).no_instances
      permission(:any).may(:show).in_same_layer_or_public_or_participating
    end
  end

  def in_same_layer_or_public_or_participating
    any_of(if_globally_visible_or_participating,
      {groups: {layer_group_id: user.groups.map(&:layer_group_id).uniq}})
  end

  def in_same_layer_or_public_or_participating_if_any_role
    all_of(if_any_role, in_same_layer_or_public_or_participating)
  end

  def if_globally_visible_or_participating
    any_of(globally_visible,
      {external_applications: true},
      ({shared_access_token: user.shared_access_token} if user.shared_access_token.present?),
      participating)
  end

  def no_instances
    AbilityDsl::Condition::NEVER
  end

  def for_qualify_event
    in_events_with_permission(:qualify)
  end

  def if_in_course_group
    {} if contains_any?(user_group_ids, course_offerers)
  end

  def if_full_permission_in_course_layer
    {} if contains_any?(user_context.permission_layer_ids(:layer_full) +
                        user_context.permission_layer_ids(:layer_and_below_full),
      course_offerers)
  end

  def if_layer_and_below_full_on_root
    {} if user_context.permission_layer_ids(:layer_and_below_full).include?(Group.root_id)
  end

  def for_participations_read_events_or_visible_fellow_participants
    any_of(for_participations_read_events, all_of({participations_visible: true}, participating))
  end

  private

  def event_condition(condition)
    condition
  end

  def course_offerers
    user_context.course_offerers
  end

  # Events without a value use the default from the settings.
  def globally_visible
    {globally_visible: Settings.event.globally_visible_by_default ? [true, nil] : true}
  end

  def participating
    event_ids = user_context.participations.map(&:event_id)
    {id: event_ids} if event_ids.present?
  end
end
