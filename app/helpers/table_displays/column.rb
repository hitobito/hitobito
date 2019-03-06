#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays
  class Column
    attr_reader :template, :table

    def initialize(template, name: nil, table: nil)
      @template = template
      @table = table
      @name = name
    end

    def table_display
      @table_display ||= template.current_person.table_display_for(template.parent)
    end

    def label
      Person.human_attribute_name(name)
    end

    def render
      header = table.sort_header(name, Person.human_attribute_name(name))

      table.col(header) do |object|
        object, attr = navigate(object, name.split('.'))
        table_display.with_permission_check(attr, object) do
          template.format_attr(object, attr)
        end
      end
    end

    def navigate(object, parts)
      [parts[0...-1].inject(object) { |obj, msg| obj.send(msg) }, parts.last]
    end

    def name
      @name || self.class.to_s.demodulize.underscore
    end
  end
end
