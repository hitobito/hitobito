module Dropdown
  module Event
    class GroupFilter < Dropdown::Base
      
      attr_reader :year
      
      def initialize(template, year, group_id)
        super(template, group_id.to_i > 0  ? Group.find(group_id).name : "Alle Gruppen")
        @year = year
        init_items
      end
      
      private
      
      def init_items
        year_param = { year: year }
        item("Alle Gruppen", template.list_courses_path(year_param))
        Group.course_offerers.each do |group|
          link = template.list_courses_path(year_param.merge(group_id: group.id))
          item(group.name, link)
        end
      end
    end
  end
end