# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
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

    def if_layer_group
      group.layer?
    end

    private

    def group
      subject.group
    end

  end
end
