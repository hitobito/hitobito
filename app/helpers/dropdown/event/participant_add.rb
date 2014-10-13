# encoding: utf-8

#  Copyright (c) 2014 insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  module Event
    class ParticipantAdd < Dropdown::Base

      attr_reader :group, :event

      def initialize(template, group, event, label, icon, url_options = {})
        super(template, label, icon)
        @group = group
        @event = event
        init_items(url_options)
      end

      def to_s
        if items.size == 1
          simple_button(items.first.url)
        else
          super
        end
      end

      def disabled_button
        simple_button('#', class: 'disabled')
      end

      private

      def simple_button(url, options = {})
        template.action_button(label, url, icon, options)
      end

      def init_items(url_options)
        participant_roles.each do |type|
          opts = url_options.merge(event_role: { type: type.sti_name })
          link = template.new_group_event_participation_path(group, event, opts)
          add_item(translate(:as, role: type.label), link)
        end
      end

      def participant_roles
        event.klass.role_types.select(&:participant?)
      end
    end
  end
end
