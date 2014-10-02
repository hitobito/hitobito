# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Group

  on(Role) do
    permission(:group_full).may(:create, :update, :destroy, :details).in_same_group

    permission(:layer_full).may(:create, :details, :create_in_subgroup, :role_types).
                            in_same_layer
    permission(:layer_full).may(:update, :destroy).in_same_layer

    permission(:layer_and_below_full).
      may(:create, :details, :create_in_subgroup, :role_types).
      in_same_layer_or_below
    permission(:layer_and_below_full).may(:update, :destroy).in_same_layer_or_visible_below

    general.non_restricted
    general(:create).group_not_deleted
    general(:destroy).not_permission_giving
  end

  def in_same_layer_or_visible_below
    in_same_layer ||
    (subject.visible_from_above? && permission_in_layers?(group.layer_hierarchy.collect(&:id)))
  end

  def non_restricted
    !subject.restricted?
  end

  # A role giving the current user the permission required to edit/destroy this very role.
  # Should not be removed because this cannot be undone by the user.
  def not_permission_giving
    subject.person_id != user.id ||
    ([:layer_and_below_full, :layer_full, :group_full] & subject.permissions).blank?
  end

  private

  def group
    subject.group
  end

end
