# frozen_string_literal: true

#  Copyright (c) 2025, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class MailingListReadables < GroupReadables
  def initialize(user)
    super

    can :index, MailingList, accessible_mailing_lists
  end

  private

  def accessible_mailing_lists
    return MailingList.all if user.root?

    MailingList.joins(:group).where(accessible_conditions.to_a).distinct
  end

  def accessible_conditions
    OrCondition.new.tap do |condition|
      in_same_group_condition(condition)
      in_above_group_condition(condition)
      in_same_layer_condition(condition)
      in_above_layer_condition(condition)
    end
  end

  def in_above_layer_condition(condition)
    layer_groups_above.each do |group|
      condition.or(
        "#{Group.quoted_table_name}.lft >= ? AND #{Group.quoted_table_name}.rgt <= ? ",
        group.lft, group.rgt
      )
    end
  end

  def subscribable_condition(condition)
    condition.or(subscribable: true)
  end
end
