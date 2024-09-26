#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Person

  on(Person) do
    class_side(:index).everybody
    class_side(:index_people_without_role).if_admin

    permission(:admin).may(:destroy).not_self
    permission(:admin).may(:totp_reset).all
    permission(:admin).may(:totp_disable).if_two_factor_authentication_not_enforced

    permission(:any).may(:show, :update, :update_email, :primary_group, :totp_reset, :security)
      .herself
    permission(:any)
      .may(:show_details, :show_full, :history, :log, :index_invoices, :update_settings)
      .herself_unless_only_basic_permissions_roles
    permission(:any).may(:totp_disable).herself_if_two_factor_authentication_not_enforced

    permission(:contact_data).may(:show).other_with_contact_data

    permission(:group_read).may(:show, :show_details).in_same_group

    permission(:group_full).may(:show_full, :history).in_same_group
    permission(:group_full)
      .may(:update, :primary_group, :send_password_instructions, :log, :index_tags, :manage_tags,
        :security)
      .non_restricted_in_same_group
    permission(:group_full).may(:update_email).if_permissions_in_all_capable_groups
    permission(:group_full).may(:create).all # restrictions are on Roles

    permission(:group_and_below_read).may(:show, :show_details).in_same_group_or_below

    permission(:group_and_below_full)
      .may(:show_full, :history)
      .in_same_group_or_below
    permission(:group_and_below_full)
      .may(:update, :primary_group, :send_password_instructions, :log, :index_tags, :manage_tags,
        :security)
      .non_restricted_in_same_group_or_below
    permission(:group_and_below_full)
      .may(:update_email)
      .if_permissions_in_all_capable_groups_or_above
    permission(:group_and_below_full).may(:create).all # restrictions are on Roles

    permission(:layer_read)
      .may(:show, :show_full, :show_details, :history)
      .in_same_layer

    permission(:layer_full)
      .may(:update, :primary_group, :send_password_instructions, :log, :approve_add_request,
        :index_tags, :manage_tags, :index_notes, :security)
      .non_restricted_in_same_layer
    permission(:layer_full).may(:update_email).if_permissions_in_all_capable_groups_or_layer
    permission(:layer_full).may(:create).all # restrictions are on Roles
    permission(:layer_full).may(:show).deleted_people_in_same_layer
    permission(:layer_full).may(:totp_reset).in_same_layer

    permission(:layer_and_below_read)
      .may(:show, :show_full, :show_details, :history)
      .in_same_layer_or_visible_below

    permission(:layer_and_below_full)
      .may(:update, :primary_group, :send_password_instructions, :log, :approve_add_request,
        :index_tags, :manage_tags, :index_notes, :security)
      .non_restricted_in_same_layer_or_visible_below
    permission(:layer_and_below_full)
      .may(:update_email)
      .if_permissions_in_all_capable_groups_or_layer_or_above
    permission(:layer_and_below_full).may(:create).all # restrictions are on Roles
    permission(:layer_and_below_full).may(:show).deleted_people_in_same_layer_or_below
    permission(:layer_and_below_full).may(:totp_reset).in_same_layer_or_below

    permission(:finance).may(:index_invoices).in_same_layer_or_below
    permission(:finance).may(:create_invoice).in_same_layer_or_below

    permission(:admin).may(:show).people_without_roles

    permission(:impersonation).may(:impersonate_user).all

    permission(:any).may(:update_password).if_password_present

    general(:send_password_instructions).not_self

    class_side(:create_households).if_any_writing_permissions
    class_side(:query).if_any_writing_permissions_or_any_leaded_events
  end

  def if_any_writing_permissions
    writing_permissions = [:group_full, :group_and_below_full,
      :layer_full, :layer_and_below_full]
    contains_any?(writing_permissions, user_context.all_permissions)
  end

  def if_any_writing_permissions_or_any_leaded_events
    if_any_writing_permissions || user_context.events_with_permission(:event_full).any?
  end

  def in_layer_group
    contains_any?(user.finance_groups.collect(&:id), person.layer_group_ids)
  end

  def not_self
    subject.id != user.id
  end

  def people_without_roles
    subject.roles.empty?
  end

  def if_two_factor_authentication_not_enforced
    !subject.two_factor_authentication_enforced?
  end

  def herself_if_two_factor_authentication_not_enforced
    herself && if_two_factor_authentication_not_enforced
  end

  def herself_unless_only_basic_permissions_roles
    return false if user.roles.any? && user.basic_permissions_only?

    herself
  end

  def if_password_present
    user.encrypted_password.present?
  end

  def if_permissions_in_all_capable_groups
    !subject.root? &&
      # true if capable roles is empty.
      capable_roles.all? do |role|
        permission_in_group?(role.group_id)
      end
  end

  def if_permissions_in_all_capable_groups_or_above
    !subject.root? &&
      # true if capable roles is empty.
      capable_roles.all? do |role|
        capable_group_roles?(role.group)
      end
  end

  def if_permissions_in_all_capable_groups_or_layer
    !subject.root? &&
      # true if capable roles is empty.
      capable_roles.all? do |role|
        permission_in_layer?(role.group.layer_group_id) ||
          capable_group_roles?(role.group)
      end
  end

  def if_permissions_in_all_capable_groups_or_layer_or_above
    !subject.root? &&
      # true if capable roles is empty.
      capable_roles.all? do |role|
        permission_in_layers?(role.group.layer_hierarchy.collect(&:id)) ||
          capable_group_roles?(role.group)
      end
  end

  def deleted_people_in_same_layer
    permission_in_layer?(Group::DeletedPeople.group_for_deleted(subject)&.layer_group_id)
  end

  def deleted_people_in_same_layer_or_below
    group_hierarchy_for_deleted = Group::DeletedPeople.group_for_deleted(subject)
      &.layer_group
      &.hierarchy
      &.pluck(:id)
    permission_in_layers?(group_hierarchy_for_deleted || [])
  end

  def capable_group_roles?(group)
    user_context.permission_group_ids(:group_full).include?(group.id) ||
      contains_any?(user_context.permission_group_ids(:group_and_below_full),
        group.local_hierarchy.collect(&:id))
  end

  # Roles of the subject that are capable of doing at least something a their group
  def capable_roles
    # restricted roles are not included because the may not be modified
    # in their group (and thus are not vulnerable to email updates)
    subject.roles.reject { |r| r.class.restricted? || r.class.permissions.blank? }
  end

  def person
    subject
  end
end
