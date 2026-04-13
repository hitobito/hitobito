#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupsFilter < ActiveRecord::Base
  belongs_to :parent, class_name: "Group"

  validates_by_schema

  def entries
    parent.self_and_descendants.where(type: group_type).where(archived_at: [active_at.., nil])
  end

  def to_s
    I18n.t("groups_filter.description",
      group_type_plural: group_type.constantize.model_name.human(count: 2),
      parent: parent.to_s)
  end
end
