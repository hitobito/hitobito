# frozen_string_literal: true

#  Copyright (c) 2017-2023 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

class Group::DeletedPeople

  class << self

    def deleted_for_multiple(layer_groups)
      Person.with_last_active_role
            .joins("INNER JOIN #{Role.quoted_table_name} " \
                   "ON people.last_active_role_id = #{Role.quoted_table_name}.id")
            .joins("INNER JOIN #{Group.quoted_table_name} " \
                   "ON #{Group.quoted_table_name}.id = roles.group_id")
            .where("#{Role.quoted_table_name}.deleted_at <= ?", Time.zone.now.to_s(:db))
            .where("#{Group.quoted_table_name}.layer_group_id IN (?)", layer_groups.map(&:id))
            .distinct
    end

    def deleted_for(layer_group)
      Person.with_last_active_role
            .joins("INNER JOIN #{Role.quoted_table_name} " \
                   "ON people.last_active_role_id = #{Role.quoted_table_name}.id")
            .joins("INNER JOIN #{Group.quoted_table_name} " \
                   "ON #{Group.quoted_table_name}.id = roles.group_id")
            .where("#{Role.quoted_table_name}.deleted_at <= ?", Time.zone.now.to_s(:db))
            .where("#{Group.quoted_table_name}.layer_group_id = ?", layer_group.id)
            .distinct
    end

    def group_for_deleted(person)
      person.last_active_role&.group
    end
  end

end
