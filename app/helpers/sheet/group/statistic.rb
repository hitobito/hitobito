# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Sheet
  class Group < Base
    class Statistic < Base
      self.parent_sheet = Sheet::Group

      def initialize(view, parent_sheet = nil, group = nil)
        super
        @active_statistic_key = view.controller.statistic_key
        build_tabs
      end

      def path_args
        [group]
      end

      private

      # Override to build tabs dynamically based on available statistics for the group.
      # The base class uses static tab definitions, but statistics are registered dynamically
      # via the Registry pattern and may vary by group type and wagon configuration.
      # This method queries the Registry for statistics available to the current group
      # and creates a tab for each, using the statistic's key as a routing parameter.
      def build_tabs
        self.class.tabs = available_statistics.map do |stat_class|
          Sheet::Tab.new(
            stat_class.label_key,
            :group_statistic_path,
            params: stat_class.key
          )
        end
      end

      # Override to find the active tab by statistic key instead of current page path.
      # Since all statistics tabs use the same route (group_statistic_path) with different
      # parameters (the statistic key), the base class logic that checks current_page won't work.
      # Instead, we match the tab whose params equal the active_statistic_key from the controller.
      def find_active_tab
        tabs&.find { |tab| tab.params == @active_statistic_key } || tabs&.first
      end

      def available_statistics
        @available_statistics ||= ::Group::Statistics::Registry.available_for(group)
      end

      def group
        @group ||= view.instance_variable_get(:@group) || entry
      end
    end
  end
end
