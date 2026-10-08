# frozen_string_literal: true

#  Copyright (c) 2012-2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl::Constraints
  # Conditions on the person of the subject, see #person_condition.
  module Person
    def herself
      person_condition(id: user.id) if user.id
    end

    def other_with_contact_data
      person_condition(contact_data_visible: true)
    end

    def in_same_group
      in_groups({id: user_group_ids})
    end

    def readable_in_same_group
      in_groups({id: user_group_ids}, roles: :roles_with_ended_readable)
    end

    def in_same_group_or_below
      in_groups(any_of(*below_groups(user_group_ids)))
    end

    def readable_in_same_group_or_below
      in_groups(any_of(*below_groups(user_group_ids)), roles: :roles_with_ended_readable)
    end

    def in_same_layer
      in_groups({layer_group_id: user_layer_ids})
    end

    def readable_in_same_layer
      in_groups({layer_group_id: user_layer_ids}, roles: :roles_with_ended_readable)
    end

    def in_same_layer_or_visible_below
      any_of(in_same_layer, visible_below)
    end

    def readable_in_same_layer_or_visible_below
      any_of(readable_in_same_layer, readable_visible_below)
    end

    def in_same_layer_or_below
      in_groups({lft: below_layers(user_layer_ids)})
    end

    def visible_below
      in_groups({lft: below_layers(user_layer_ids)}, role_types: visible_role_types)
    end

    def readable_visible_below
      in_groups({lft: below_layers(user_layer_ids)},
        role_types: visible_role_types, roles: :roles_with_ended_readable)
    end

    def non_restricted_in_same_group
      in_groups({id: user_group_ids}, role_types: non_restricted_role_types)
    end

    def non_restricted_in_same_group_or_below
      in_groups(any_of(*below_groups(user_group_ids)), role_types: non_restricted_role_types)
    end

    def non_restricted_in_same_layer
      in_groups({layer_group_id: user_layer_ids}, role_types: non_restricted_role_types)
    end

    def non_restricted_in_same_layer_or_visible_below
      any_of(non_restricted_in_same_layer,
        visible_below,
        all_of(in_same_layer_or_below, can_see_invisible_in_layer_or_above))
    end

    def can_see_invisible_in_layer_or_above
      layer_ids = user_see_invisible_layer_ids
      in_groups({lft: below_layers(layer_ids)}) if layer_ids.present?
    end

    private

    # Nests a condition on a person under the association of the subject leading to the person.
    def person_condition(condition)
      condition
    end

    # People with a role in a group matching the given condition.
    def in_groups(group_condition, roles: :roles, role_types: nil)
      return if group_condition.nil?

      role_condition = role_types ? {type: role_types} : {}
      person_condition(nested(roles, group_condition_with_type(group_condition, role_condition)))
    end

    def group_condition_with_type(group_condition, role_condition)
      all_of(role_condition, nested(:group, group_condition))
    end

    def visible_role_types
      Role.visible_types.map(&:sti_name)
    end

    def non_restricted_role_types
      Role.all_types.reject(&:restricted?).map(&:sti_name)
    end
  end
end
