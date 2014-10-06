# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
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

    def in_same_layer
      permission_in_layers?(event.groups.collect(&:layer_group_id))
    end

    def in_same_layer_or_below
      permission_in_layers?(event.groups.collect { |g| g.layer_hierarchy.collect(&:id) }.flatten)
    end

    def at_least_one_group_not_deleted
      event.groups.present? &&
      event.groups.any? { |group| !group.deleted? }
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
