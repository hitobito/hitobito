# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Person

  on(Person) do
    class_side(:index, :query).everybody
    class_side(:index_people_without_role).if_admin

    permission(:admin).may(:destroy).not_self
    
    permission(:any).may(:show, :show_full, :history, :update,
                         :update_email, :primary_group, :log).
                     herself

    permission(:contact_data).may(:show).other_with_contact_data

    permission(:group_read).may(:show, :show_details).in_same_group

    permission(:group_full).may(:show_full, :history).in_same_group
    permission(:group_full).
      may(:update, :primary_group, :send_password_instructions, :log).
      non_restricted_in_same_group
    permission(:group_full).may(:update_email).if_permissions_in_all_capable_groups
    permission(:group_full).may(:create).all # restrictions are on Roles

    permission(:group_and_below_read).may(:show, :show_details).in_same_group_or_below

    permission(:group_and_below_full).
      may(:show_full, :history).
      in_same_group_or_below
    permission(:group_and_below_full).
      may(:update, :primary_group, :send_password_instructions, :log).
      non_restricted_in_same_group_or_below
    permission(:group_and_below_full).
      may(:update_email).
      if_permissions_in_all_capable_groups_or_above
    permission(:group_and_below_full).may(:create).all # restrictions are on Roles

    permission(:layer_read).
      may(:show, :show_full, :show_details, :history).
      in_same_layer

    permission(:layer_full).
      may(:update, :primary_group, :send_password_instructions, :log, :approve_add_request,
          :index_tags, :manage_tags, :index_notes).
      non_restricted_in_same_layer
    permission(:layer_full).may(:update_email).if_permissions_in_all_capable_groups_or_layer
    permission(:layer_full).may(:create).all # restrictions are on Roles

    permission(:layer_and_below_read).
      may(:show, :show_full, :show_details, :history).
      in_same_layer_or_visible_below

    permission(:layer_and_below_full).
      may(:update, :primary_group, :send_password_instructions, :log, :approve_add_request,
          :index_tags, :manage_tags, :index_notes).non_restricted_in_same_layer_or_visible_below
    permission(:layer_and_below_full).
      may(:update_email).
      if_permissions_in_all_capable_groups_or_layer_or_above
    permission(:layer_and_below_full).may(:create).all # restrictions are on Roles

    permission(:admin).may(:show).people_without_roles

    general(:send_password_instructions).not_self
  end

  def not_self
    subject.id != user.id
  end

  def people_without_roles
    subject.roles.empty?
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
