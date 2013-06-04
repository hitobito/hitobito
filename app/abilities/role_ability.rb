class RoleAbility < AbilityDsl::Base

  include AbilityDsl::Conditions::Group

  on(Role) do
    permission(:group_full).may(:create, :update, :destroy).in_same_group
    permission(:layer_full).may(:create).in_same_layer_or_below
    permission(:layer_full).may(:update, :destroy).in_same_layer_or_visible_below
  end

  def general_conditions
    !subject.restricted? &&
    case action
    when :create then !group.deleted?
    when :destroy then not_permission_giving
    else true
    end
  end

  def in_same_layer_or_visible_below
    in_same_layer ||
    (subject.visible_from_above? && permission_in_layers?(group.layer_groups.collect(&:id)))
  end

  private

  def group
    subject.group
  end

  def not_permission_giving
    subject.person_id != user.id ||
    ([:layer_full, :group_full] & subject.permissions).blank?
  end

end