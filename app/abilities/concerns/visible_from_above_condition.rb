module VisibleFromAboveCondition
  extend ActiveSupport::Concern

  def visible_from_above_condition(condition)
    return if layer_groups_above.blank?

    visible_from_above_groups = OrCondition.new
    collapse_groups_to_highest(layer_groups_above) do |layer_group|
      visible_from_above_groups.or("#{Group.quoted_table_name}.lft >= ? " \
                                   "AND #{Group.quoted_table_name}.rgt <= ?",
        layer_group.lft, layer_group.rgt)
    end

    query = "(#{visible_from_above_groups.to_a.first}) AND roles.type IN (?)"
    args = visible_from_above_groups.to_a[1..] + [Role.visible_types.collect(&:sti_name)]
    condition.or(query, *args)
  end

  def see_invisible_from_above_condition(condition)
    return if layer_groups_see_invisible_from_above.blank?

    see_invisible_from_above_groups = OrCondition.new
    collapse_groups_to_highest(layer_groups_see_invisible_from_above) do |layer_group|
      see_invisible_from_above_groups.or("groups.lft >= ? AND groups.rgt <= ?",
        layer_group.left,
        layer_group.rgt)
    end

    condition.or(*see_invisible_from_above_groups.to_a)
  end

  def layer_groups_see_invisible_from_above
    @layer_groups_unconfined_below ||= Group.where(id: layer_group_ids_with_permissions(:see_invisible_from_above))
  end

  private

  # If group B is a child of group A, B is collapsed into A.
  # e.g. input [A,B] -> output A
  def collapse_groups_to_highest(layer_groups)
    layer_groups.each do |group|
      unless layer_groups.any? { |g| g.is_ancestor_of?(group) }
        yield group
      end
    end
  end
end
