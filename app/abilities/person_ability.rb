class PersonAbility < AbilityDsl::Base

  on(Person) do
    permission(:any).may(:index, :query).all

    permission(:any).may(:show, :show_full, :history, :update, :primary_group).herself
    permission(:contact_data).may(:show).other_with_contact_data
    permission(:group_read).may(:show, :show_details).in_same_group
    permission(:layer_read).may(:show, :show_full, :show_details, :history).in_same_layer_or_visible_below
    permission(:group_full).may(:show_full, :show_details, :history).in_same_group
    permission(:group_full).may(:update, :primary_group, :send_password_instructions).non_restricted_in_same_group
    permission(:layer_full).may(:update, :primary_group, :send_password_instructions).non_restricted_in_same_layer_or_visible_below

    # restrictions are on roles
    permission(:group_full).may(:create).all
    permission(:layer_full).may(:create).all
  end

  def general_conditions
    case action
    when :send_password_instructions then user.id != subject.id
    else true
    end
  end

  def herself
    subject.id == user.id
  end

  def other_with_contact_data
    subject.contact_data_visible?
  end

  def in_same_group
    permission_in_groups?(subject.groups)
  end

  def in_same_layer_or_visible_below
    permission_in_layers?(subject.layer_group_ids) ||
    permission_in_layers?(subject.above_groups_visible_from)
  end

  def non_restricted_in_same_group
    permission_in_groups?(subject.non_restricted_groups)
  end

  def non_restricted_in_same_layer_or_visible_below
    permission_in_layers?(subject.non_restricted_groups.collect(&:layer_group_id).uniq) ||
    permission_in_layers?(subject.above_groups_visible_from)
  end
end