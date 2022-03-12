# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl::Constraints
  module Group

    # uses the group where the corresponding permission is defined
    def in_same_group
      group && permission_in_group?(group.id)
    end

    def in_same_layer
      group && permission_in_layer?(group.layer_group_id)
    end

    def in_same_group_or_below
      group &&
      permission_in_groups?(group.local_hierarchy.collect(&:id))
    end

    # uses the layers where the corresponding permission is defined
    def in_same_layer_or_below
      group && permission_in_layers?(group.layer_hierarchy.collect(&:id))
    end

    def group_not_deleted
      !group.deleted?
    end

    def group_not_deleted_or_archived
      group_not_deleted && in_active_group
    end

    def if_layer_group
      group.layer?
    end

    def if_layer_group_if_active
      if_layer_group && in_active_group
    end

    def in_active_group
      !group.archived?
    end

    def in_archived_group
      group.archived?
    end

    def in_same_group_if_active
      in_same_group && in_active_group
    end

    def in_same_layer_if_active
      in_same_layer && in_active_group
    end

    def in_same_group_or_below_if_active
      in_same_group_or_below && in_active_group
    end

    def in_same_layer_or_below_if_active
      in_same_layer_or_below && in_active_group
    end

    private

    def group
      subject.group
    end

  end
end
