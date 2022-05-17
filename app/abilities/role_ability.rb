# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Group

  on(Role) do
    class_side(:role_types, :details).all

    permission(:group_full).may(:create, :update, :destroy)
                           .in_same_group_if_active

    permission(:group_and_below_full).may(:create, :update, :destroy)
                                     .in_same_group_or_below_if_active

    permission(:layer_full).may(:create, :create_in_subgroup, :update, :destroy)
                           .in_same_layer_if_active

    permission(:layer_and_below_full).
      may(:create, :create_in_subgroup, :update, :destroy).
      in_same_layer_or_visible_below

    general.non_restricted
    general(:create).group_not_deleted_or_archived
    general(:destroy).not_permission_giving
  end

  def in_same_layer_or_visible_below
    in_same_layer_if_active ||
      (
        subject.visible_from_above? &&
        permission_in_layers?(group.layer_hierarchy.collect(&:id)) &&
        in_active_group
      )
  end

  def non_restricted
    !subject.restricted?
  end

  # A role giving the current user the permission required to edit/destroy this very role.
  # Should not be removed because this cannot be undone by the user.
  def not_permission_giving
    not_own_role? ||
      ([:layer_and_below_full, :layer_full, :group_full] & subject.permissions).blank?
  end

  def not_own_role?
    subject.person_id != user.id
  end

  private

  def group
    subject.group
  end

end
