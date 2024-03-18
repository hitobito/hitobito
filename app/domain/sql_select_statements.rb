class SqlSelectStatements
  # generates select list with MAX aggregate function with all arguments of passed model
  def generate_aggregate_queries(*table_names)
    select_list = []

    table_names.each do |table_name|
      columns = table_name.titleize.gsub(' ', '::').constantize.columns
      table = table_name.titleize.gsub(' ', '::').constantize.arel_table

      max_columns = columns.map do |column|
        if column.type != :boolean
          "MAX(#{table_name.pluralize}.#{column.name}) AS #{column.name}"
        else
          "bool_and(#{table_name.pluralize}.#{column.name}) AS #{column.name}"
        end
      end

      select_list.concat(max_columns)
    end

    select_list.join(', ')
  end
end