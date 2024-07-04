#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This class is only used for fetching lists based on a group association.
class PersonReadables < GroupBasedReadables
  attr_reader :group

  def initialize(user, group = nil, roles_join = nil)
    super(user)

    @roles_join = roles_join || {roles: :group}
    @group = group

    if @group.nil?
      can :index, Person, accessible_people { |_| true }
    else # optimized queries for a given group
      group_accessible_people
    end
  end

  private

  def group_accessible_people
    if read_permission_for_this_group?
      can :index, Person,
        group.people.only_public_data { |_| true }

    elsif layer_and_below_read_in_above_layer?
      can :index, Person,
        group.people.only_public_data.visible_from_above(group) { |_| true }

    elsif contact_data_visible?
      can :index, Person,
        group.people.only_public_data.contact_data_visible { |_| true }
    end
  end

  def accessible_people
    if user.root?
      Person.only_public_data
    else
      scope = Person.only_public_data.where(accessible_conditions.to_a).distinct
      if has_group_based_conditions?
        # Only add these joins when really necessary, because they are extremely expensive to
        # compute when there are a lot of people and roles
        scope = scope.joins(@roles_join).where(groups: {deleted_at: nil})
      end
      scope
    end
  end

  def accessible_conditions
    OrCondition.new.tap do |condition|
      condition.or(*herself_condition)
      condition.or(*contact_data_condition) if contact_data_visible?
      see_invisible_from_above_condition(condition)
      append_group_conditions(condition)
    end
  end

  def has_group_based_conditions?
    layer_groups_see_invisible_from_above.present? ||
      groups_same_group.present? ||
      groups_above_group.present? ||
      layer_groups_same_layer.present? ||
      layer_groups_above.present?
  end

  def contact_data_condition
    ["people.contact_data_visible = ?", true]
  end

  def herself_condition
    ["people.id = ?", user.id]
  end

  def read_permission_for_this_group?
    user.root? ||
      group_read_in_this_group? ||
      group_read_in_above_group? ||
      layer_read_in_same_layer? ||
      layer_and_below_read_in_same_layer? ||
      see_invisible_from_above_in_above_layer?
  end

  def contact_data_visible?
    user.contact_data_visible?
  end

  def group_read_in_this_group?
    permission_group_ids(:group_read).include?(group.id)
  end

  def group_read_in_above_group?
    ids = permission_group_ids(:group_and_below_read)
    ids.present? && (ids & group.local_hierarchy.collect(&:id)).present?
  end

  def layer_read_in_same_layer?
    permission_layer_ids(:layer_read).include?(group.layer_group_id)
  end

  def layer_and_below_read_in_same_layer?
    permission_layer_ids(:layer_and_below_read).include?(group.layer_group_id)
  end

  def layer_and_below_read_in_above_layer?
    ids = permission_layer_ids(:layer_and_below_read)
    ids.present? && (ids & group.layer_hierarchy.collect(&:id)).present?
  end

  def see_invisible_from_above_in_above_layer?
    layers_see_invisible_from_above.present? &&
      (layers_see_invisible_from_above & group.layer_hierarchy.collect(&:id)).present?
  end

  def layers_see_invisible_from_above
    @layers_see_invisible_from_above ||=
      user_context.layer_ids(user.groups_with_permission(:see_invisible_from_above).to_a)
  end
end
