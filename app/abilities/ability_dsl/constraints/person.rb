# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl::Constraints
  module Person

    def herself
      person.id == user.id
    end

    def other_with_contact_data
      person.contact_data_visible?
    end

    def in_same_group
      permission_in_groups?(person.group_ids)
    end

    def in_same_group_or_below
      permission_in_groups?(person.groups.collect(&:local_hierarchy).flatten.collect(&:id).uniq)
    end

    def in_same_layer
      permission_in_layers?(person.layer_group_ids)
    end

    def in_same_layer_or_visible_below
      in_same_layer || visible_below
    end

    def in_same_layer_or_below
      permission_in_layers?(person.groups_hierarchy_ids)
    end

    def visible_below
      permission_in_layers?(person.above_groups_where_visible_from.collect(&:id))
    end

    def non_restricted_in_same_group
      permission_in_groups?(person.non_restricted_groups.collect(&:id))
    end

    def non_restricted_in_same_group_or_below
      permission_in_groups?(
        person.non_restricted_groups.collect(&:local_hierarchy).flatten.collect(&:id).uniq)
    end

    def non_restricted_in_same_layer
      permission_in_layers?(person.non_restricted_groups.collect(&:layer_group_id))
    end

    def non_restricted_in_same_layer_or_visible_below
      non_restricted_in_same_layer || visible_below
    end

  end
end
