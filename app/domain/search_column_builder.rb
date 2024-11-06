# Copyright (c) 2017-2024, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

# Adds a tsvector column to each model that includes the FullTextSearchable module,
# enabling full-text search functionality. Also adds a GIN index for faster querying.

class SearchColumnBuilder
  class_attribute :searchable_models, default: [
    Person, Group, Event, Invoice, Address
  ]

  class_attribute :association_mappings, default: {
    event_translations: Event::Translation
  }

  SEARCH_COLUMN = :search_column

  def initialize(drop_columns: true)
    @drop_columns = drop_columns
  end

  # Select models with FullTextSearchable module included (exlcuding STI subclasses)
  def run
    # Process each searchable model to add a tsvector column and a GIN index
    searchable_models.each do |model|
      next unless connection.table_exists?(model.table_name)

      with_resetting_model(model) do
        create_columns_for_attrs(model, model::SEARCHABLE_ATTRS)
      end
    end
  end

  private

  def with_resetting_model(model)
    model.ignored_columns += [:search_column]
    yield
    model.reset_column_information
  end

  # Create searchable columns for main table and associations
  def create_columns_for_attrs(model, attrs)
    create_searchable_column_and_index(model, model.table_name, attrs.select { |attr| attr.is_a?(Symbol) })

    attrs.select { |attr| attr.is_a?(Hash) }.each do |associated_columns|
      create_columns_for_association(associated_columns)
    end
  end

  # Create searchable column on associated tables
  def create_columns_for_association(associated_columns)
    associated_columns.each do |table, columns|
      model_class = table.to_s.classify.safe_constantize || association_mappings.fetch(table.to_sym)
      with_resetting_model(model_class) do
        create_searchable_column_and_index(model_class, model_class.table_name, columns)
      end
    end
  end

  # Adds or replaces a tsvector column and associated GIN index on specified columns
  def create_searchable_column_and_index(model, table_name, attrs)
    # check if every attribute exists on the table (after_initilize is also called before the wagon migrations so the wagon attributes still don't exist)
    attrs.each do |attr|
      return unless connection.column_exists?(table_name, attr.to_s)
    end
    return if connection.column_exists?(table_name, SEARCH_COLUMN) && !drop_columns?

    quoted_table_name = connection.quote_table_name(table_name)

    migration.remove_column(quoted_table_name, SEARCH_COLUMN) if connection.column_exists?(quoted_table_name, SEARCH_COLUMN)
    migration.remove_index(quoted_table_name, name: "#{table_name}_search_column_gin_idx") if connection.index_exists?(quoted_table_name, :search_column, using: :gin)

    create_search_column(table_name, quoted_table_name, attrs)
    create_search_index(table_name, quoted_table_name)
  end

  def create_search_column(table_name, quoted_table_name, attrs)
    statement = <<~SQL
      ALTER TABLE #{quoted_table_name}
      ADD COLUMN #{SEARCH_COLUMN} tsvector GENERATED ALWAYS AS (
        #{ts_vector_statement(attrs)}
      ) STORED;
    SQL
    connection.execute(statement)
  end

  def create_search_index(table_name, quoted_table_name)
    connection.execute <<~SQL
      CREATE INDEX "#{table_name}_search_column_gin_idx" ON #{quoted_table_name} USING GIN (#{SEARCH_COLUMN});
    SQL
  end

  def ts_vector_statement(attrs)
    "to_tsvector(
      'simple',
      #{attrs.map { |attr|
        if attr == :birthday # or any other date field, when another date field, other than birthday will become searchable, please add method to check for type here
          convert_date_field_to_text(connection.quote_column_name(attr))
        else
          "COALESCE(#{connection.quote_column_name(attr)}::text, '')"
        end
      }.join(" || ' ' || ")}
    )"
  end

  def convert_date_field_to_text(quoted_column_name)
    "CASE
      WHEN #{quoted_column_name} IS NOT NULL THEN
        EXTRACT(YEAR FROM #{quoted_column_name})::TEXT || '-' ||
        LPAD(EXTRACT(MONTH FROM #{quoted_column_name})::TEXT, 2, '0') || '-' ||
        LPAD(EXTRACT(DAY FROM #{quoted_column_name})::TEXT, 2, '0')
      ELSE ''
    END"
  end

  def drop_columns? = @drop_columns

  def connection = ActiveRecord::Base.connection

  def migration = ActiveRecord::Migration
end
