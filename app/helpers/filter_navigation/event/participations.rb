# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FilterNavigation
  module Event
    class Participations < FilterNavigation::Base

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
        elsif predefined_filters.include?(filter)
          @active_label = predefined_filter_label(filter)
        elsif filter.blank?
          @active_label = predefined_filter_label(predefined_filters.first)
        end
      end

      def init_items
        predefined_filters.each do |key|
          item(predefined_filter_label(key), event_participation_filter_link(key), counts[key])
        end
      end

      def predefined_filter_label(key)
        translate("predefined_filters.#{key}")
      end

      def counts
        @counts ||= template.instance_variable_get('@counts') || {}
      end

      def init_dropdown_items
        role_labels.each do |label|
          dropdown.add_item(label, event_participation_filter_link(label))
        end
      end

      def role_labels
        @role_labels ||= event.participation_role_labels
      end

      def event_participation_filter_link(filter)
        template.group_event_participations_path(group, event, filter: filter)
      end

      def predefined_filters
        ::Event::ParticipationFilter::PREDEFINED_FILTERS
      end
    end
  end
end
