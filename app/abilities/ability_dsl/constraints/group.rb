# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl::Constraints
  # Conditions on the group of the subject, see #group_condition.
  module Group
    # uses the group where the corresponding permission is defined
    def in_same_group
      group_condition(id: user_group_ids)
    end

    def in_same_layer
      group_condition(layer_group_id: user_layer_ids)
    end

    def in_same_group_or_below
      group_condition(any_of(*below_groups(user_group_ids)))
    end

    # uses the layers where the corresponding permission is defined
    def in_same_layer_or_below
      group_condition(lft: below_layers(user_layer_ids))
    end

    def group_not_deleted
      group_condition(deleted_at: nil)
    end

    def group_not_deleted_or_archived
      group_condition(deleted_at: nil, archived_at: nil)
    end

    def if_layer_group
      group_condition(type: layer_group_types)
    end

    def if_layer_group_if_active
      group_condition(type: layer_group_types, archived_at: nil)
    end

    def in_active_group
      group_condition(archived_at: nil)
    end

    def in_archived_group
      none_of(group_condition(archived_at: nil))
    end

    def in_same_group_if_active
      all_of(in_same_group, in_active_group)
    end

    def in_same_layer_if_active
      all_of(in_same_layer, in_active_group)
    end

    def in_same_group_or_below_if_active
      all_of(in_same_group_or_below, in_active_group)
    end

    def in_same_layer_or_below_if_active
      all_of(in_same_layer_or_below, in_active_group)
    end

    def on_root_group
      group_condition(parent_id: nil)
    end

    private

    # Nests a condition on a group under the association of the subject leading to the group.
    def group_condition(condition)
      nested(:group, condition)
    end

    def layer_group_types
      sti_names(::Group.all_types.select(&:layer))
    end
  end
end
