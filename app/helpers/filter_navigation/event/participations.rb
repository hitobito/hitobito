# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FilterNavigation
  module Event
    class Participations < FilterNavigation::Base

      PREDEFINED_FILTERS = %w(all teamers participants)

      attr_reader :group, :event, :filter

      delegate :can?, to: :template

      def initialize(template, group, event, filter)
        super(template)
        @group = group
        @event = event
        @filter = filter.to_s
        init_labels
        init_items
        init_dropdown_items
      end

      private

      def init_labels
        if role_labels.include?(filter)
          dropdown.label = filter
          dropdown.active = true
        elsif PREDEFINED_FILTERS.include?(filter)
          @active_label = predefined_filter_label(filter)
        elsif filter.blank?
          @active_label = predefined_filter_label(PREDEFINED_FILTERS.first)
        end
      end

      def init_items
        PREDEFINED_FILTERS.each do |key|
          item(predefined_filter_label(key), event_participation_filter_link(key))
        end
      end

      def predefined_filter_label(key)
        translate("predefined_filters.#{key}")
      end

      def init_dropdown_items
        role_labels.each do |label|
          dropdown.item(label, event_participation_filter_link(label))
        end
      end

      def role_labels
        @role_labels ||= event.participation_role_labels
      end

      def event_participation_filter_link(filter)
        template.group_event_participations_path(group, event, filter: filter)
      end
    end
  end
end
