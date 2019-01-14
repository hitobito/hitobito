# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
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
      table.col(header) do |person|
        table_display.with_permission_check(name, person) do
          template.format_attr(person, name)
        end
      end
    end

    def name
      @name || self.class.to_s.demodulize.underscore
    end
  end
end
