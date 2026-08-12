# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module VisibleFromAboveCondition
  extend ActiveSupport::Concern

  def visible_from_above_condition(condition)
    query = Group.in_subtrees_of(layer_groups_above)
    return if query.nil?

    condition.or("(#{query}) AND roles.type IN (?)", Role.visible_types.collect(&:sti_name))
  end

  def see_invisible_from_above_condition(condition)
    query = Group.in_subtrees_of(layer_groups_see_invisible_from_above)
    return if query.nil?

    condition.or(query)
  end

  def layer_groups_see_invisible_from_above
    @layer_groups_unconfined_below ||= Group.where(
      id: layer_group_ids_with_permissions(:see_invisible_from_above)
    )
  end
end
