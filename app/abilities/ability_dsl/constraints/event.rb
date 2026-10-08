# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl::Constraints
  # Conditions on the event of the subject, see #event_condition.
  module Event
    def for_leaded_events
      in_events_with_permission(:event_full)
    end

    def for_participations_read_events
      any_of(in_events_with_permission(:participations_read),
        for_participations_read_details_events)
    end

    def for_participations_read_details_events
      any_of(in_events_with_permission(:participations_read_details),
        for_participations_full_events)
    end

    def for_participations_full_events
      in_events_with_permission(:participations_full)
    end

    def in_same_group
      event_condition(groups: {id: user_group_ids})
    end

    def in_same_group_if_active
      all_of(in_same_group, at_least_one_group_not_deleted)
    end

    def in_same_group_or_below
      event_condition(nested(:groups, any_of(*below_groups(user_group_ids))))
    end

    def in_same_group_or_below_if_active
      all_of(in_same_group_or_below, at_least_one_group_not_deleted)
    end

    def in_same_layer
      event_condition(groups: {layer_group_id: user_layer_ids})
    end

    def in_same_layer_if_active
      all_of(in_same_layer, at_least_one_group_not_deleted)
    end

    def in_same_layer_or_below
      event_condition(groups: {lft: below_layers(user_layer_ids)})
    end

    def in_same_layer_or_below_if_active
      all_of(in_same_layer_or_below, at_least_one_group_not_deleted)
    end

    def at_least_one_group_not_deleted
      event_condition(groups: {deleted_at: nil, archived_at: nil})
    end

    private

    # Nests a condition on an event under the association of the subject leading to the event.
    def event_condition(condition)
      nested(:event, condition)
    end

    def in_events_with_permission(permission)
      event_ids = user_context.events_with_permission(permission)
      event_condition(id: event_ids) if event_ids.present?
    end
  end
end
