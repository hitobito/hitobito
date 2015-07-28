# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This class is only used for fetching lists based on a group association.
class PersonFullReadables < PersonReadables

  self.same_group_permissions = [:group_full]

  delegate :groups_group_full, to: :user_context

  private

  def contact_data_visible?
    false
  end

  def group_read_in_this_group?
    groups_group_full.include?(group.id)
  end

end
