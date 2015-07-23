# encoding: utf-8


#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

# Commnon Base Class for fetching people.
class PersonFetchables

  include CanCan::Ability

  attr_reader :user_context

  delegate :user, to: :user_context

  def initialize(user)
    @user_context = AbilityDsl::UserContext.new(user)
  end

  private

  def in_same_layer_condition(layer_groups)
    ['groups.layer_group_id IN (?)', layer_groups.collect(&:id)]
  end

  def visible_from_above_condition(layer_groups)
    visible_from_above_groups = OrCondition.new
    collapse_groups_to_highest(layer_groups) do |layer_group|
      visible_from_above_groups.or('groups.lft >= ? AND groups.rgt <= ?',
                                   layer_group.left,
                                   layer_group.rgt)
    end

    query = "(#{visible_from_above_groups.to_a.first}) AND roles.type IN (?)"
    args = visible_from_above_groups.to_a[1..-1] + [Role.visible_types.collect(&:sti_name)]
    [query, *args]
  end

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
