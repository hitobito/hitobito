module TableDisplaysHelper

  def render_table_display_columns(table)
    current_person.table_display_for(parent).selected.each do |column|
      render_table_display_column(table, column)
    end
  end

  def render_table_display_column(table, column)
    TableDisplays::Column.new(self, table: table, name: column).render
  end

end
