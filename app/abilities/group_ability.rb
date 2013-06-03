class GroupAbility < AbilityDsl::Base

  include AbilityDsl::Conditions::Group

  on(Group) do
    permission(:any).may(:read, :index_events, :index_mailing_lists).all
    permission(:any).may(:deleted_subgroups).unless_external

    permission(:group_read).may(:show_details).in_same_group
    permission(:layer_read).may(:show_details).in_same_layer_or_below

    permission(:layer_full).may(:create).with_parent_in_same_layer_or_below
    permission(:layer_full).may(:destroy).in_same_layer_or_below_except_permission_giving
    permission(:layer_full).may(:update, :reactivate).in_same_layer_or_below
    permission(:layer_full).may(:modify_superior).in_below_layers
    permission(:group_full).may(:update, :reactivate).in_same_group


    permission(:contact_data).may(:index_people).all
    permission(:group_read).may(:index_people, :index_local_people).in_same_group
    permission(:group_full).may(:index_full_people).in_same_group
    permission(:layer_read).may(:index_people, :index_full_people, :index_deep_full_people).in_same_layer_or_below
    permission(:layer_read).may(:index_local_people).in_same_layer
  end

  def general_conditions
    case action
    when :update then !group.deleted?
    else true
    end
  end

  def with_parent_in_same_layer_or_below
    parent = group.parent
    parent && !parent.deleted? && permission_in_layers?(parent.layer_groups)
  end

  def in_same_layer_or_below_except_permission_giving
    in_same_layer_or_below &&
    !(user_context.groups_layer_full.include?(group.id) ||
      user_context.layers_full.include?(group.id))
  end

  def in_below_layers
    permission_in_layers?(group.upper_layer_groups)
  end

  def unless_external
    user.roles.any? {|r| !r.class.external? }
  end

  private

  def group
    subject
  end

end