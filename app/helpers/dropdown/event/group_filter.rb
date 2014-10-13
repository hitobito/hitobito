# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  module Event
    class GroupFilter < Dropdown::Base

      attr_reader :year

      def initialize(template, year, group_id)
        super(template, group_id.to_i > 0  ? Group.find(group_id).name : translate(:all_groups))
        @year = year
        init_items
      end

      private

      def init_items
        year_param = { year: year }
        add_item('Alle Gruppen', template.list_courses_path(year_param))
        Group.course_offerers.each do |group|
          link = template.list_courses_path(year_param.merge(group_id: group.id))
          add_item(group.name, link)
        end
      end
    end
  end
end
