# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Group

  on(Group) do # rubocop:disable Metrics/BlockLength
    permission(:any)
      .may(:read, :index_events, :"index_event/courses", :index_mailing_lists)
      .if_any_role
    permission(:any)
      .may(:register_people) # via API with session cookie
      .in_self_registration_groups

    permission(:contact_data).may(:index_people).all

    # local people are the ones not visible from above
    permission(:group_read).may(:show_details, :index_people, :index_local_people).in_same_group
    permission(:group_and_below_read)
      .may(:show_details, :index_people, :index_local_people)
      .in_same_group_or_below

    permission(:group_full)
      .may(:index_full_people, :export_events, :"export_event/courses", :reactivate,
        :deleted_subgroups)
      .in_same_group
    permission(:group_full).may(:update).in_same_group_if_active

    permission(:group_and_below_full)
      .may(:index_full_people, :reactivate, :export_events, :"export_event/courses",
        :deleted_subgroups)
      .in_same_group_or_below
    permission(:group_and_below_full).may(:update).in_same_group_or_below_if_active
    permission(:group_and_below_full).may(:create).with_parent_in_same_group_hierarchy
    permission(:group_and_below_full).may(:destroy).in_below_group

    permission(:layer_read)
      .may(:show_details, :index_people, :index_local_people, :index_full_people,
        :index_deep_full_people, :export_events, :"export_event/courses")
      .in_same_layer

    permission(:layer_full).may(:create).with_parent_in_same_layer
    permission(:layer_full).may(:destroy).in_same_layer_except_permission_giving
    permission(:layer_full).may(:index_service_tokens).service_token_in_same_layer
    permission(:layer_full).may(:index_question_templates).in_same_layer
    permission(:layer_full)
      .may(:index_person_add_requests, :index_notes, :index_deleted_people, :show_statistics,
        :index_calendars, :deleted_subgroups).in_same_layer
    permission(:layer_full)
      .may(:update, :reactivate,
        :manage_person_tags, :activate_person_add_requests, :deactivate_person_add_requests)
      .in_same_layer_if_active

    permission(:layer_and_below_read)
      .may(:show_details, :index_people, :index_full_people, :index_deep_full_people,
        :export_subgroups, :export_events, :"export_event/courses")
      .in_same_layer_or_below
    permission(:layer_and_below_read).may(:index_local_people).in_same_layer

    permission(:layer_and_below_full).may(:create).with_parent_in_same_layer_or_below
    permission(:layer_and_below_full).may(:destroy).in_same_layer_or_below_except_permission_giving
    permission(:layer_and_below_full)
      .may(:update, :reactivate, :index_person_add_requests, :index_notes, :show_statistics,
        :manage_person_tags, :index_deleted_people, :deleted_subgroups).in_same_layer_or_below
    permission(:layer_and_below_full).may(:modify_superior).in_below_layers_if_active
    permission(:layer_and_below_full).may(:index_service_tokens).service_token_in_same_layer
    permission(:layer_and_below_full).may(:index_question_templates).in_same_layer
    permission(:layer_and_below_full).may(:index_calendars).in_same_layer
    permission(:layer_and_below_full)
      .may(:activate_person_add_requests, :deactivate_person_add_requests)
      .in_same_layer_if_active

    permission(:see_invisible_from_above).may(:index_local_people).in_same_layer_or_below

    permission(:finance).may(:index_issued_invoices).for_finance_layer_ids
    permission(:finance).may(:create_invoices_from_list).in_same_layer_or_below_if_active
    permission(:finance).may(:index_received_invoices).in_same_layer_or_below
    permission(:finance).may(:create_invoice).in_same_layer_or_below

    permission(:admin).may(:manage_person_duplicates).if_layer_group_if_active
    permission(:layer_and_below_full).may(:manage_person_duplicates).if_permission_in_layer

    permission(:manual_deletion)
      .may(:manually_delete_people)
      .if_permission_in_layer
    permission(:admin).may(:manually_delete_people).all

    permission(:layer_full).may(:log).in_same_layer_if_active
    permission(:layer_and_below_full).may(:log).in_same_layer_or_below_if_active
    permission(:group_full).may(:log).in_same_group_if_active
    permission(:group_and_below_full).may(:log).in_same_group_or_below_if_active

    permission(:admin).may(:set_main_self_registration_group).in_active_group
    permission(:admin).may(:sync_addresses).on_root_group

    general(:update).group_not_deleted
    general(:index_person_add_requests,
      :activate_person_add_requests,
      :deactivate_person_add_requests)
      .if_layer_group
  end

  def if_permission_in_layer
    {id: user_layer_ids}
  end

  def for_finance_layer_ids
    {id: user_finance_layer_ids}
  end

  def with_parent_in_same_layer
    {type: non_layer_group_types, parent: {deleted_at: nil, layer_group_id: user_layer_ids}}
  end

  def with_parent_in_same_layer_or_below
    {parent: {deleted_at: nil, lft: below_layers(user_layer_ids)}}
  end

  def with_parent_in_same_group_hierarchy
    all_of({type: non_layer_group_types},
      nested(:parent, all_of({deleted_at: nil}, any_of(*below_groups(user_group_ids)))))
  end

  def in_below_group
    all_of(none_of(id: user_group_ids), in_same_group_or_below)
  end

  def in_same_layer_except_permission_giving
    all_of(in_same_layer, except_permission_giving)
  end

  def in_same_layer_or_below_except_permission_giving
    all_of(in_same_layer_or_below, except_permission_giving)
  end

  def except_permission_giving
    group_ids = [:layer_and_below_full, :layer_full].flat_map do |permission|
      user_context.permission_group_ids(permission) + user_context.permission_layer_ids(permission)
    end
    group_ids.empty? ? {} : none_of(id: group_ids.uniq)
  end

  # New groups do not have a layer group yet, so the layers above are derived from the parent.
  def in_below_layers
    any_of({layer_group: {lft: strictly_below_layers(user_layer_ids)}},
      {id: nil, type: layer_group_types, parent: {lft: below_layers(user_layer_ids)}},
      {id: nil, type: non_layer_group_types,
       parent: {layer_group: {lft: strictly_below_layers(user_layer_ids)}}})
  end

  def in_below_layers_if_active
    all_of(in_below_layers, in_active_group)
  end

  # Member is a general role kind. Return true if user has any member role anywhere.
  def if_member
    {} if user.roles.any? { |r| r.class.member? }
  end

  def service_token_in_same_layer
    in_same_layer
  end

  def in_self_registration_groups
    role_types = GroupDecorator.all_allowed_roles_for_self_registration.map(&:sti_name)
    {self_registration_role_type: role_types, archived_at: nil}
  end

  private

  def group_condition(condition)
    condition
  end

  def non_layer_group_types
    sti_names([Group, *Group.all_types.reject(&:layer)])
  end

  def strictly_below_layers(layer_ids)
    below_layers(layer_ids).map { |range| (range.begin + 1)..range.end }
  end
end
