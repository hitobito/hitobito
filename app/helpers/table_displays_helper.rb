#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplaysHelper
  def render_table_display_columns(table)
    return unless Settings.table_displays

    current_person.table_display_for(parent).selected.each do |column|
      render_table_display_column(table, column)
    end
  end

  def render_table_display_column(table, column)
    if TableDisplay::Participations::QUESTION_REGEX.match(column)
      TableDisplays::QuestionColumn.new(self, table: table, name: column).render
    else
      TableDisplays::Column.new(self, table: table, name: column).render
    end
  end
end
