# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  module Event
    class RoleAdd < Dropdown::Base

      attr_reader :group, :event

      def initialize(template, group, event)
        label = translate("add_to_#{event.klass.name.underscore}", default: full_translation_key(:add))
        super(template, label, :plus)
        @group = group
        @event = event
        init_items
      end

      private

      def init_items
        event.klass.role_types.reject(&:restricted?).each do |type|
          link = template.new_group_event_role_path(group,
                                                    event,
                                                    event_role: { type: type.sti_name })
          add_item(type.label, link)
        end
      end
    end
  end
end
