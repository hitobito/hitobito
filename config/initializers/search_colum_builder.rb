#  Copyright (c) 2017-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Add ts_vector column to each model and associated models that is searchable with full text search
# Additionaly to that, we also add a GIN index, to speed things up

Rails.application.config.after_initialize do
  Rails.application.eager_load!

  models_with_module = ActiveRecord::Base.descendants.select do |model|
    model.included_modules.include?("FullTextSearchable".constantize)
  end

  models_with_module.select do |model|
    model.base_class == model
  end.each do |model|
    if ActiveRecord::Base.connection.table_exists? model.table_name
      searchable_attrs = model::SEARCHABLE_ATTRS.select { |element| element.is_a?(Symbol) }

      create_searchable_column(model.table_name, searchable_attrs)

      model::SEARCHABLE_ATTRS.find { |element| element.is_a?(Hash) }&.each do |key, values|
        create_searchable_column(key.to_s, values.flatten)
      end
    end
  end
end

def create_searchable_column(model, searchable_attrs)
  tsvector_string = <<-SQL
    to_tsvector(
        'simple', 
        #{searchable_attrs.map { |attr| "COALESCE(#{attr}::text, '')" }.join(" || ' ' || ")}
    )
  SQL

  alter_table_sql = <<-SQL
    ALTER TABLE #{model}
    ADD COLUMN search_column tsvector GENERATED ALWAYS AS (
        #{tsvector_string}
    ) STORED;
  SQL

  unless ActiveRecord::Base.connection.column_exists?(model, "search_column")
    begin
      ActiveRecord::Base.connection.execute(alter_table_sql)
      puts "Successfully added search_column to the #{model} table."
      unless ActiveRecord::Base.connection.index_exists?(model, :search_column, using: :gin)
        index_name = "#{model}_search_column_gin_idx"
    
        ActiveRecord::Base.connection.execute <<-SQL
          CREATE INDEX #{index_name}
          ON #{model}
          USING GIN (search_column);
        SQL
      end
    rescue => e
      puts "An error occurred: #{e.message}"
    end
  end
end