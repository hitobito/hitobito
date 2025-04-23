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

    def readable_in_same_group
      permission_in_groups?(person.roles_with_ended_readable.collect(&:group_id))
    end

    def in_same_group_or_below
      permission_in_groups?(local_hiearchy_ids(person.groups))
    end

    def readable_in_same_group_or_below
      permission_in_groups?(local_hiearchy_ids(person.groups_with_roles_ended_readable))
    end

    def in_same_layer
      permission_in_layers?(person.layer_group_ids)
    end

    def readable_in_same_layer
      permission_in_layers?(person.groups_with_roles_ended_readable.map(&:layer_group_id).uniq)
    end

    def in_same_layer_or_visible_below
      in_same_layer || visible_below
    end

    def readable_in_same_layer_or_visible_below
      readable_in_same_layer || readable_visible_below
    end

    def in_same_layer_or_below
      permission_in_layers?(person.groups_hierarchy_ids)
    end

    def visible_below
      permission_in_layers?(person.above_groups_where_visible_from.collect(&:id))
    end

    def readable_visible_below
      groups = person.groups_where_visible_from_above(person.roles_with_ended_readable)
      permission_in_layers?(person.above_groups_where_visible_from(groups).collect(&:id))
    end

    def non_restricted_in_same_group
      permission_in_groups?(person.non_restricted_groups.collect(&:id))
    end

    def non_restricted_in_same_group_or_below
      permission_in_groups?(local_hiearchy_ids(person.non_restricted_groups))
    end

    def non_restricted_in_same_layer
      permission_in_layers?(person.non_restricted_groups.collect(&:layer_group_id))
    end

    def non_restricted_in_same_layer_or_visible_below
      non_restricted_in_same_layer || visible_below
    end

    def local_hiearchy_ids(groups)
      groups.collect(&:local_hierarchy).flatten.collect(&:id).uniq
    end
  end
end
