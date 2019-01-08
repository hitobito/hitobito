# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays
  class Columns
    attr_reader :table, :template

    delegate :parent, :current_person, to: :template

    def initialize(table, template)
      @table = table
      @template = template
    end

    def to_s
      table_display.selected.each do |column|
        table.sortable_attr(column)
      end
    end

    def table_display
      @table_display ||= template.current_person.table_displays.
        find_or_initialize_by(parent_id: template.parent.id, parent_type: template.parent.class.base_class)
    end
  end
end
