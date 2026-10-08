# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Group

  on(Role) do
    class_side(:role_types, :details).all

    permission(:any).may(:index).of_fully_readable_people

    permission(:group_full).may(:show, :create, :update, :destroy, :terminate)
      .in_same_group_if_active

    permission(:group_and_below_full).may(:show, :create, :update, :destroy, :terminate)
      .in_same_group_or_below_if_active

    permission(:layer_full).may(:show, :create, :create_in_subgroup, :update, :destroy, :terminate)
      .in_same_layer_if_active

    permission(:layer_and_below_full)
      .may(:show, :create, :create_in_subgroup, :update, :destroy, :terminate)
      .in_same_layer_or_visible_below

    permission(:any).may(:terminate).her_own

    general.non_restricted
    general(:create).group_not_deleted_or_archived
    general(:destroy).not_permission_giving
  end

  def of_fully_readable_people
    {person_id: accessible_ids(Person, :show_full)}
  end

  def in_same_layer_or_visible_below
    all_of(in_active_group,
      any_of(in_same_layer,
        all_of(in_same_layer_or_below,
          any_of({type: visible_role_types}, can_see_invisible_in_layer_or_above))))
  end

  def non_restricted
    {type: role_types_where { |r| !r.restricted? }}
  end

  # A role giving the current user the permission required to edit/destroy this very role.
  # Should not be removed because this cannot be undone by the user.
  def not_permission_giving
    any_of(not_own_role, {type: non_permission_giving_role_types})
  end

  def not_own_role
    none_of(her_own)
  end

  def can_see_invisible_in_layer_or_above
    layer_ids = user_see_invisible_layer_ids
    group_condition(lft: below_layers(layer_ids)) if layer_ids.present?
  end

  def her_own
    {person_id: user.id} if user.id
  end

  private

  def visible_role_types
    role_types_where(&:visible_from_above)
  end

  def non_permission_giving_role_types
    giving = [:layer_and_below_full, :layer_full, :group_full]
    role_types_where { |r| (giving & r.permissions).blank? }
  end

  # Includes new roles without a type yet.
  def role_types_where(&)
    sti_names([Role, *Role.all_types].select(&))
  end
end
