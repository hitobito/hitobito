#  Copyright (c) 2012-2022, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class TableDisplays < PeopleAddress
    prepend RenderTableDisplays

    self.model_class = ::Person
    self.row_class = TableDisplayRow

    attr_reader :table_display, :selected_group

    def initialize(list, table_display, selected_group)
      super(add_table_display_to_query(list, table_display.person, selected_group))
      @table_display = table_display
      @selected_group = selected_group
      @table_display.selected_group = selected_group
    end

    def build_attribute_labels
      super.merge(selected_labels)
    end

    def selected_labels
      table_display.active_columns(list).each_with_object({}) do |attr, hash|
        hash[attr] = attribute_label(attr) unless table_display.column_for(attr).exclude_attr?(selected_group)
      end
    end

    def row_for(entry, format = nil)
      row_class.new(entry, table_display, format)
    end

    def attribute_label(attr)
      column = table_display.column_for(attr)
      column.present? ? column.label(attr) : super
    end
  end
end
