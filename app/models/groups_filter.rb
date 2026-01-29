#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupsFilter < ActiveRecord::Base
  belongs_to :parent, class_name: "Group"

  def entries
    parent.self_and_descendants.where(type: group_type).where(archived_at: [active_at.., nil])
  end
end
