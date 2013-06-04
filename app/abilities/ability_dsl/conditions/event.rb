module AbilityDsl::Conditions
  module Event
    def for_leaded_events
      permission_in_event?(:full)
    end

    def for_event_contacts
      permission_in_event?(:contact_data)
    end

    def in_same_group
      permission_in_groups?(event.group_ids)
    end

    def in_same_layer
      permission_in_layers?(event.groups.collect(&:layer_group_id))
    end

    def in_same_layer_or_below
      permission_in_layers?(event.groups.collect {|g| g.layer_groups.collect(&:id) }.flatten)
    end

    private

    def event
      subject.event
    end

    def permission_in_event?(permission)
      user_context.events_with_permission(permission).include?(event.id)
    end

    def at_least_one_group_not_deleted
      event.groups.present? &&
      event.groups.any? {|group| !group.deleted? }
    end
  end
end