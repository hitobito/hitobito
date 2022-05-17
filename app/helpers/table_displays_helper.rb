#  Copyright (c) 2012-2022, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplaysHelper

  def render_table_display_columns(model_class, table)
    TableDisplay.active_columns_for(current_person, model_class, table.entries).each do |column|
      render_table_display_column(model_class, table, column)
    end
  end

  def render_table_display_column(model_class, table, column)
    current_person.table_display_for(model_class).column_for(column, table: table).render(column)
  end
end
