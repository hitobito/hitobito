class RoleAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Group

  on(Role) do
    permission(:group_full).may(:create, :update, :destroy).in_same_group
    permission(:layer_full).may(:create).in_same_layer_or_below
    permission(:layer_full).may(:update, :destroy).in_same_layer_or_visible_below

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

  def not_permission_giving
    subject.person_id != user.id ||
    ([:layer_full, :group_full] & subject.permissions).blank?
  end

  private

  def group
    subject.group
  end

end