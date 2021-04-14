# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  module Event
    class GroupFilter < Dropdown::Base
      def initialize(template, group_id)
        title = group_id.to_i.positive? ? Group.find(group_id).name : translate(:all_groups)
        super(template, title)
        init_items
      end

      private

      def init_items
        add_item('Alle Gruppen', template.list_courses_path)
        Group.course_offerers.each do |group|
          link = template.list_courses_path(group_id: group.id)
          add_item(group.name, link)
        end
      end
    end
  end
end
