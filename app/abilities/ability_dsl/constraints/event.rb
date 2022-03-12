# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


module AbilityDsl::Constraints
  module Event
    def for_leaded_events
      permission_in_event?(:event_full)
    end

    def for_participations_read_events
      permission_in_event?(:participations_read) ||
      for_participations_full_events
    end

    def for_participations_full_events
      permission_in_event?(:participations_full)
    end

    def in_same_group
      permission_in_groups?(event.group_ids)
    end

    def in_same_group_if_active
      in_same_group && at_least_one_group_not_deleted
    end

    def in_same_group_or_below
      permission_in_groups?(event.groups.collect(&:local_hierarchy).flatten.collect(&:id).uniq)
    end

    def in_same_group_or_below_if_active
      in_same_group_or_below && at_least_one_group_not_deleted
    end

    def in_same_layer
      permission_in_layers?(event.groups.collect(&:layer_group_id))
    end

    def in_same_layer_if_active
      in_same_layer && at_least_one_group_not_deleted
    end

    def in_same_layer_or_below
      permission_in_layers?(event.groups.collect(&:layer_hierarchy).flatten.collect(&:id).uniq)
    end

    def in_same_layer_or_below_if_active
      in_same_layer_or_below && at_least_one_group_not_deleted
    end

    def at_least_one_group_not_deleted
      event.groups.present? &&
        event.groups.any? { |group| !group.deleted? && !group.archived? }
    end

    private

    def event
      subject.event
    end

    def permission_in_event?(permission)
      user_context.events_with_permission(permission).include?(event.id)
    end

  end
end
