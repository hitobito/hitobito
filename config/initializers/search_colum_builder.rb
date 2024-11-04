# Copyright (c) 2017-2024, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

# Adds a tsvector column to each model that includes the FullTextSearchable module,
# enabling full-text search functionality. Also adds a GIN index for faster querying.

Rails.application.config.after_initialize do
  Rails.application.eager_load!

  # Select models with FullTextSearchable module included (exlcuding STI subclasses)
  searchable_models = ActiveRecord::Base.descendants.select do |model|
    model.included_modules.include?(FullTextSearchable) && model.base_class == model
  end

  # Process each searchable model to add a tsvector column and a GIN index
  searchable_models.each do |model|
    next unless ActiveRecord::Base.connection.table_exists?(model.table_name)

    # Create searchable column on main table
    searchable_attrs = model::SEARCHABLE_ATTRS.select { |attr| attr.is_a?(Symbol) }
    create_searchable_column_and_index(model.table_name, searchable_attrs, model_instance: model)

    # Create searchable column on associated tables
    model::SEARCHABLE_ATTRS.select { |attr| attr.is_a?(Hash) }.each do |assoc|
      assoc.each do |table, columns|
        create_searchable_column_and_index(table.to_s, columns.flatten)
      end
    end
  end
end

# Adds or replaces a tsvector column and associated GIN index on specified columns
def create_searchable_column_and_index(table_name, searchable_attrs, model_instance: nil)
  quoted_table_name = ActiveRecord::Base.connection.quote_table_name(table_name)

  if ActiveRecord::Base.connection.table_exists?(quoted_table_name)
    ActiveRecord::Migration.remove_column(quoted_table_name, "search_column") if ActiveRecord::Base.connection.column_exists?(quoted_table_name, "search_column")
    ActiveRecord::Migration.remove_index(quoted_table_name, name: "#{table_name}_search_column_gin_idx") if ActiveRecord::Base.connection.index_exists?(quoted_table_name, :search_column, using: :gin)
  end

  search_column_statement = <<~SQL
    ALTER TABLE #{quoted_table_name}
    ADD COLUMN search_column tsvector GENERATED ALWAYS AS (
      to_tsvector(
        'simple', 
        #{searchable_attrs.map { |attr| "COALESCE(#{ActiveRecord::Base.connection.quote_column_name(attr)}::text, '')" }.join(" || ' ' || ")}
      )
    ) STORED;
  SQL

  begin
    ActiveRecord::Base.connection.execute(search_column_statement)
    puts "Successfully added search_column to the #{table_name} table."
    unless model_instance.nil?
      model_instance.ignored_columns = [:search_column]
    end

    # Re-add the GIN index for the search column
    index_name = "#{table_name}_search_column_gin_idx"
    ActiveRecord::Base.connection.execute <<~SQL
      CREATE INDEX #{index_name}
      ON #{quoted_table_name}
      USING GIN (search_column);
    SQL
  rescue => e
    puts "An error occurred while creating search_column and index on #{table_name}: #{e.message}"
  end
end
