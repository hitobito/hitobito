# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Person

  WRITING_PERMISSIONS = [:group_full, :group_and_below_full, :layer_full,
    :layer_and_below_full].freeze

  on(Person) do # rubocop:todo Metrics/BlockLength
    class_side(:index_people_without_role).if_admin

    permission(:admin).may(:destroy).not_self
    permission(:admin).may(:totp_reset).all
    permission(:admin).may(:totp_disable).if_two_factor_authentication_not_enforced

    permission(:any).may(:security).herself
    permission(:any)
      .may(:index_received_invoices, :update_settings)
      .herself_unless_only_basic_permissions_roles
    permission(:any).may(:totp_disable).herself_if_two_factor_authentication_not_enforced

    permission(:contact_data).may(:index, :show).other_with_contact_data

    permission(:group_read).may(:index, :show_details, :index_messages).in_same_group
    permission(:group_read).may(:show).readable_in_same_group

    permission(:group_full).may(:show_full, :history).in_same_group
    permission(:group_full)
      .may(:update, :primary_group, :send_password_instructions, :log,
        :show_tags, :create_tags, :assign_tags, :security)
      .non_restricted_in_same_group
    permission(:group_full).may(:update_email).if_permissions_in_all_capable_groups
    permission(:group_full).may(:create).all # restrictions are on Roles

    permission(:group_and_below_read)
      .may(:index, :show_details, :index_messages)
      .in_same_group_or_below
    permission(:group_and_below_read).may(:show).readable_in_same_group_or_below

    permission(:group_and_below_full)
      .may(:show_full, :history)
      .in_same_group_or_below
    permission(:group_and_below_full)
      .may(:update, :primary_group, :send_password_instructions, :log,
        :show_tags, :create_tags, :assign_tags, :security)
      .non_restricted_in_same_group_or_below
    permission(:group_and_below_full)
      .may(:update_email)
      .if_permissions_in_all_capable_groups_or_above
    permission(:group_and_below_full).may(:create).all # restrictions are on Roles

    permission(:layer_read)
      .may(:index, :show_full, :show_details, :history, :index_messages)
      .in_same_layer
    permission(:layer_read)
      .may(:show)
      .readable_in_same_layer

    permission(:layer_full)
      .may(:update, :primary_group, :send_password_instructions, :log, :approve_add_request,
        :show_tags, :create_tags, :assign_tags, :index_notes, :security)
      .non_restricted_in_same_layer
    permission(:layer_full).may(:update_in_layer).in_same_layer
    permission(:layer_full).may(:update_email).if_permissions_in_all_capable_groups_or_layer
    permission(:layer_full).may(:create).all # restrictions are on Roles
    permission(:layer_full).may(:show).deleted_people_in_same_layer
    permission(:layer_full).may(:totp_reset).in_same_layer

    permission(:layer_and_below_read)
      .may(:index, :show_full, :show_details, :history, :index_messages)
      .in_same_layer_or_visible_below
    permission(:layer_and_below_read)
      .may(:show)
      .readable_in_same_layer_or_visible_below

    permission(:see_invisible_from_above)
      .may(:index, :show, :show_full, :show_details, :history)
      .in_same_layer_or_below

    permission(:layer_and_below_full)
      .may(:update, :primary_group, :send_password_instructions, :log, :approve_add_request,
        :show_tags, :create_tags, :assign_tags, :index_notes, :security)
      .non_restricted_in_same_layer_or_visible_below
    permission(:layer_and_below_full)
      .may(:update_in_layer)
      .in_same_layer_or_visible_below_or_seeing_invisible
    permission(:layer_and_below_full)
      .may(:update_email)
      .if_permissions_in_all_capable_groups_or_layer_or_above
    permission(:layer_and_below_full).may(:create).all # restrictions are on Roles
    permission(:layer_and_below_full).may(:show).deleted_people_in_same_layer_or_below
    permission(:layer_and_below_full).may(:totp_reset).in_same_layer_or_below

    permission(:finance).may(:index_received_invoices).in_same_layer_or_below
    permission(:finance).may(:create_received_invoice).in_same_layer_or_below

    permission(:admin).may(:show).people_without_roles

    permission(:impersonation).may(:impersonate_user).all

    permission(:any).may(:update_password).if_password_present
    permission(:any).may(:update_in_layer).manageds

    general(:send_password_instructions).not_self

    class_side(:create_households).if_any_writing_permissions
    class_side(:query).if_any_writing_permissions_or_any_leaded_events

    # Managers have almost all base permissions on the managed person
    for_self_or_manageds do
      permission(:any).may(:show, :update, :update_email, :primary_group, :totp_reset).herself

      permission(:any)
        .may(:index, :show_details, :show_full, :index_messages)
        .herself

      permission(:any)
        .may(:history, :log)
        .herself_unless_only_basic_permissions_roles

      class_side(:create_households).if_any_writing_permission_or_any_manageds
    end

    # People with update permission on a managed person also have the permission to update the
    # managers of that managed person
    permission(:group_full).may(:change_managers)
      .non_restricted_in_same_group_except_self
    permission(:group_and_below_full).may(:change_managers)
      .non_restricted_in_same_group_or_below_except_self
    permission(:layer_full).may(:change_managers)
      .non_restricted_in_same_layer_except_self
    permission(:layer_and_below_full).may(:change_managers)
      .non_restricted_in_same_layer_or_visible_below_except_self

    class_side(:lookup_manageds).if_any_writing_permissions
  end

  def if_any_writing_permissions
    {} if any_writing_permissions?
  end

  def if_any_writing_permissions_or_any_leaded_events
    {} if any_writing_permissions? || user_context.events_with_permission(:event_full).any?
  end

  def if_any_writing_permission_or_any_manageds
    {} if any_writing_permissions? || user.manageds.any?
  end

  def not_self
    none_of(herself)
  end

  def manageds
    {id: PeopleManager.where(manager_id: user.id).select(:managed_id)} if user.id
  end

  def people_without_roles
    {roles: {id: nil}}
  end

  def if_two_factor_authentication_not_enforced
    any_of(none_of(roles: {type: sti_names(Role.types_enforcing_two_factor)}),
      {email: Settings.root_email})
  end

  def herself_if_two_factor_authentication_not_enforced
    all_of(herself, if_two_factor_authentication_not_enforced)
  end

  def herself_unless_only_basic_permissions_roles
    herself unless user.roles.any? && user.basic_permissions_only?
  end

  def if_password_present
    {} if user.encrypted_password.present?
  end

  def if_permissions_in_all_capable_groups
    with_all_capable_roles_in(id: user_group_ids)
  end

  def if_permissions_in_all_capable_groups_or_above
    with_all_capable_roles_in(groups_with_full_permission)
  end

  def if_permissions_in_all_capable_groups_or_layer
    with_all_capable_roles_in(any_of({layer_group_id: user_layer_ids}, groups_with_full_permission))
  end

  def if_permissions_in_all_capable_groups_or_layer_or_above
    with_all_capable_roles_in(any_of({lft: below_layers(user_layer_ids)},
      groups_with_full_permission))
  end

  def deleted_people_in_same_layer
    {id: Group::DeletedPeople.people_in(layer_group_id: user_layer_ids).select(:id)}
  end

  def deleted_people_in_same_layer_or_below
    {id: Group::DeletedPeople.people_in(lft: below_layers(user_layer_ids)).select(:id)}
  end

  def in_same_layer_or_visible_below_or_seeing_invisible
    any_of(in_same_layer, visible_below,
      all_of(in_same_layer_or_below, can_see_invisible_in_layer_or_above))
  end

  def non_restricted_in_same_group_except_self
    all_of(non_restricted_in_same_group, not_self)
  end

  def non_restricted_in_same_group_or_below_except_self
    all_of(non_restricted_in_same_group_or_below, not_self)
  end

  def non_restricted_in_same_layer_except_self
    all_of(non_restricted_in_same_layer, not_self)
  end

  def non_restricted_in_same_layer_or_visible_below_except_self
    all_of(non_restricted_in_same_layer_or_visible_below, not_self)
  end

  private

  def any_writing_permissions?
    contains_any?(WRITING_PERMISSIONS, user_context.all_permissions)
  end

  # Groups where the user may modify capable roles due to group permissions.
  def groups_with_full_permission
    any_of({id: user_context.permission_group_ids(:group_full)},
      *below_groups(user_context.permission_group_ids(:group_and_below_full)))
  end

  # People who are not root and whose roles that are capable of doing something in their group
  # are all in groups matching the given condition. Restricted roles are not included because
  # they may not be modified in their group.
  def with_all_capable_roles_in(group_condition)
    allowed_groups = group_condition ? AbilityDsl::Condition.to_relation(group_condition,
      Group) : Group.none
    other_capable_roles = Role.where(type: Role.capable_types.map(&:sti_name))
      .where.not(group_id: allowed_groups)
    all_of(none_of(email: Settings.root_email),
      none_of(id: other_capable_roles.select(:person_id)))
  end
end
