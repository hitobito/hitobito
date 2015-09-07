# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This class is only used for fetching lists based on a group association.
# Returns all people that are fully readable.
class PersonFullReadables < PersonReadables

  self.same_group_permissions = [:group_full, :group_and_below_full]
  self.above_group_permissions = [:group_and_below_full]

  private

  def contact_data_visible?
    false
  end

  def group_read_in_this_group?
    permission_group_ids(:group_full).include?(group.id)
  end

  def group_read_in_above_group?
    ids = permission_group_ids(:group_and_below_full)
    ids.present? && (ids & group.local_hierarchy.collect(&:id)).present?
  end

end
