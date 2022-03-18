#  Copyright (c) 2012-2022, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplaysHelper

  def render_table_display_columns(model_class, table)
    return unless Settings.table_displays

    table_display = current_person.table_display_for(parent)
    available = table_display.available(table.entries)
    table_display.selected.each do |column|
      # Exclude columns which are selected but not available
      # This prevents showing the event questions of event A in the participants list of event B
      next unless available.include? column

      render_table_display_column(model_class, table, column)
    end
  end

  def render_table_display_column(model_class, table, column)
    current_person.table_display_for(model_class).column_for(column, table: table).render(column)
  end
end
