# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  module Event
    class New < Dropdown::Base
      delegate :new_group_event_path, to: :template

      def initialize(template, group, event_type)
        super(
          template,
          template.t("events.global.link.add_#{event_type.name.underscore}"),
          :plus
          )

        @group = group
        @event_type = event_type
        @main_link = template.new_group_event_path(group, event: {type: event_type.sti_name})

        init_items
      end

      def to_s
        return "".html_safe unless template.can?(:new, new_event)

        items.empty? ? template.action_button(label, main_link, icon) : super
      end

      private

      def new_event
        @event_type.new.tap { |e| e.groups << @group }
      end

      def init_items
        ::Event.applicable_templates(@group, event_type: @event_type.sti_name).each do |t|
          add_item(t.to_s, template.new_group_event_path(@group, source_id: t.id))
        end
      end
    end
  end
end
