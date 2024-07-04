#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This class is only used for fetching lists based on a group association.
class GroupBasedReadables < GroupBasedFetchables
  self.same_group_permissions = [:group_full, :group_read,
    :group_and_below_full, :group_and_below_read]
  self.above_group_permissions = [:group_and_below_full, :group_and_below_read]
  self.same_layer_permissions = [:layer_full, :layer_read, :layer_and_below_full,
    :layer_and_below_read, :see_invisible_from_above]
  self.above_layer_permissions = [:layer_and_below_full, :layer_and_below_read,
    :see_invisible_from_above]

  delegate :permission_group_ids, :permission_layer_ids, to: :user_context
end
