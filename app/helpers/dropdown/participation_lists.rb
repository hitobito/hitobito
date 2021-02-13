#  Copyright (c) 2018, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class ParticipationLists < Dropdown::Base
    def initialize(template, group, translation)
      super(template, translation, :plus)
      @template = template
      @group = group
      init_items
    end

    private

    def init_items
      ::Event.all_types.each do |event|
        next unless authorized?(event)
        add_item(event.label,
          build_event_participation_lists_path(event),
          participation_lists_options)
      end
    end

    def authorized?(event)
      @template.can?(:"index_#{event.to_s.underscore.pluralize}", @group)
    end

    def build_event_participation_lists_path(event)
      type = event == ::Event ? nil : event.to_s
      template.group_events_participation_lists_new_path(@group, type: type, label: event.label)
    end

    def participation_lists_options
      {data: {checkable: true, method: :get}, remote: true}
    end
  end
end
