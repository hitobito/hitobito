# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonAbility < AbilityDsl::Base

  on(Person) do
    class_side(:index, :query).everybody

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
    permission(:group_full).may(:create).all  # restrictions are on Roles

    permission(:layer_read).may(:show, :show_full, :show_details, :history).
                            in_same_layer

    permission(:layer_and_below_read).may(:show, :show_full, :show_details, :history).
                            in_same_layer_or_visible_below

    permission(:layer_full).
      may(:update, :primary_group, :send_password_instructions, :log).
      non_restricted_in_same_layer
    permission(:layer_full).may(:update_email).if_permissions_in_all_capable_groups_or_layer
    permission(:layer_full).may(:create).all # restrictions are on Roles

    permission(:layer_and_below_full).
      may(:update, :primary_group, :send_password_instructions, :log).
      non_restricted_in_same_layer_or_visible_below
    permission(:layer_and_below_full).
      may(:update_email).
      if_permissions_in_all_capable_groups_or_above
    permission(:layer_and_below_full).may(:create).all # restrictions are on Roles

    general(:send_password_instructions).not_self
  end

  def herself
    subject.id == user.id
  end

  def not_self
    subject.id != user.id
  end

  def other_with_contact_data
    subject.contact_data_visible?
  end

  def in_same_group
    permission_in_groups?(subject.group_ids)
  end

  def in_same_layer
    permission_in_layers?(subject.layer_group_ids)
  end

  def in_same_layer_or_visible_below
    in_same_layer || visible_below
  end

  def non_restricted_in_same_group
    permission_in_groups?(subject.non_restricted_groups.collect(&:id))
  end

  def non_restricted_in_same_layer
    permission_in_layers?(subject.non_restricted_groups.collect(&:layer_group_id))
  end

  def non_restricted_in_same_layer_or_visible_below
    non_restricted_in_same_layer || visible_below
  end

  def visible_below
    permission_in_layers?(subject.above_groups_where_visible_from.collect(&:id))
  end

  def if_permissions_in_all_capable_groups
    !subject.root? &&
    # true if capable roles is empty.
    capable_roles.all? do |role|
      permission_in_group?(role.group_id)
    end
  end

  def if_permissions_in_all_capable_groups_or_layer
    !subject.root? &&
    # true if capable roles is empty.
    capable_roles.all? do |role|
      permission_in_layer?(role.group.layer_group_id) ||
      user_context.groups_group_full.include?(role.group_id)
    end
  end

  def if_permissions_in_all_capable_groups_or_above
    !subject.root? &&
    # true if capable roles is empty.
    capable_roles.all? do |role|
      permission_in_layers?(role.group.layer_hierarchy.collect(&:id)) ||
      user_context.groups_group_full.include?(role.group_id)
    end
  end

  # Roles of the subject that are capable of doing at least something a their group
  def capable_roles
    # restricted roles are not included because the may not be modified
    # in their group (and thus are not vulnerable to email updates)
    subject.roles.reject { |r| r.class.restricted? || r.class.permissions.blank? }
  end

end
