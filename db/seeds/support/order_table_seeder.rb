# frozen_string_literal: true

#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class OrderTableSeeder

  def seed
    return true if seeded?

    truncate_all
    insert_group_types
    insert_role_types
    insert_event_role_types
  end

  private

  def seeded?
    false
  end

  def truncate_all
    GroupTypeOrder.connection.truncate(GroupTypeOrder.table_name, 'Truncate GroupTypeOrder')
    EventRoleTypeOrder.connection.truncate(EventRoleTypeOrder.table_name, 'Truncate EventRoleTypeOrder')
    RoleTypeOrder.connection.truncate(RoleTypeOrder.table_name, 'Truncate RoleTypeOrder')
  end

  def insert_event_role_types
    Event.all_types.each do | event_type |
      event_type::role_types.each_with_index do | role_type, index|
        EventRoleTypeOrder.create(name: role_type, order_weight: index + 1)
      end
    end
  end

  def insert_group_types
    Group.all_types.each_with_index do |group_type, index|
      GroupTypeOrder.create(name: group_type, order_weight: index + 1)
    end
  end

  def insert_role_types
    Role.all_types.each_with_index do |role_type, index|
      RoleTypeOrder.create(name: role_type, order_weight: index + 1)
    end
  end
end
