# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubocop:disable Rails/HelperInstanceVariable This is a helper-CLASS
module Dropdown
  module Event
    class RoleAdd < Dropdown::Base

      attr_reader :group, :event, :person

      def initialize(template, group, event, person = nil)
        label = translate("add_to_#{event.klass.name.underscore}",
                          default: full_translation_key(:add))
        super(template, label, :plus)
        @group = group
        @event = event
        @person = person
        init_items
      end

      private

      def init_items
        event.role_types.reject(&:restricted?).each do |type|
          event_role_attrs = { type: type.sti_name }
          event_role_attrs[:person_id] = person.id if person

          link = template.new_group_event_role_path(group, event, event_role: event_role_attrs)
          add_item(type.label, link)
        end
      end
    end
  end
end
# rubocop:enable Rails/HelperInstanceVariable
