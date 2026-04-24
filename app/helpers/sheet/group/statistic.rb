# frozen_string_literal: true

#  Copyright (c) 2022-2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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

      def build_tabs
        self.class.tabs = available_statistics.map do |stat_class|
          Sheet::Tab.new(
            stat_class.label_key,
            :group_statistic_path,
            params: stat_class.key
          )
        end
      end

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
