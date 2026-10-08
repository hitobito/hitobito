# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Mailing lists whose group and event subscriptions only include people from the groups
# covered by the given permission on the group of the list.
class MailingLists::LocalSubscriptions
  PERMISSIONS = [:group_full, :group_and_below_full, :layer_full].freeze

  def initialize(permission)
    raise ArgumentError, "Unexpected permission #{permission}" if PERMISSIONS.exclude?(permission)

    @permission = permission
  end

  def lists
    MailingList
      .joins("INNER JOIN #{Group.quoted_table_name} list_groups " \
             "ON list_groups.id = #{MailingList.quoted_table_name}.group_id")
      .joins("INNER JOIN #{Group.quoted_table_name} list_layers " \
             "ON list_layers.id = list_groups.layer_group_id")
      .where(foreign_group_subscriptions.arel.exists.not)
      .where(foreign_event_subscriptions.arel.exists.not)
  end

  private

  attr_reader :permission

  def foreign_group_subscriptions
    Subscription
      .joins(:related_role_types)
      .where("subscriptions.mailing_list_id = mailing_lists.id")
      .where(subscriber_type: Group.sti_name)
      .where.not(local_role_types_condition)
      .select(1)
  end

  def foreign_event_subscriptions
    Subscription
      .where("subscriptions.mailing_list_id = mailing_lists.id")
      .where(subscriber_type: Event.sti_name)
      .where(local_event_groups.arel.exists.not)
      .select(1)
  end

  def local_event_groups
    Group.unscoped
      .joins("INNER JOIN events_groups ON events_groups.group_id = groups.id")
      .where("events_groups.event_id = subscriptions.subscriber_id")
      .where(local_groups_condition)
      .select(1)
  end

  def local_groups_condition
    case permission
    when :group_full
      "groups.id = list_groups.id"
    when :group_and_below_full
      "groups.lft >= list_groups.lft AND groups.lft < list_groups.rgt AND " \
        "groups.layer_group_id = list_groups.layer_group_id"
    when :layer_full
      "groups.layer_group_id = list_groups.layer_group_id AND groups.deleted_at IS NULL"
    end
  end

  def local_role_types_condition
    type_column = (permission == :layer_full) ? "list_layers.type" : "list_groups.type"
    conditions = Group.all_types.map do |group_type|
      Subscription.sanitize_sql_array(
        ["(#{type_column} = ? AND related_role_types.role_type IN (?))",
          group_type.sti_name, local_role_types(group_type).map(&:sti_name).presence || [""]]
      )
    end
    conditions.join(" OR ")
  end

  def local_role_types(group_type)
    if permission == :group_full
      group_type.role_types
    else
      Role::TypeList.new(group_type).role_types[group_type.label].values.flatten
    end
  end
end
