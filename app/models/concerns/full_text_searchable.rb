#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FullTextSearchable
  SEARCH_COLUMN = :search_column

  TS_QUERY_CHARS = ["(", ")", ":", "&", "|", "!"]

  def self.included(model)
    model.ignored_columns += [SEARCH_COLUMN]

    model.define_singleton_method(:search) do |term|
      # Use & to make sure every word in term has to match the result
      sanitized_term = term.split.map do |t|
        ActiveRecord::Base.sanitize_sql_like(t).delete(*TS_QUERY_CHARS.join) + ":*"
      end.join(" & ")

      # Generate base search query and rank for main model
      base_query = "#{model.table_name}.#{SEARCH_COLUMN} @@ to_tsquery('simple', '#{sanitized_term}')"
      base_rank = "COALESCE(ts_rank(#{model.table_name}.#{SEARCH_COLUMN}, to_tsquery('simple', '#{sanitized_term}')), 0)"

      associated_tables = model::SEARCHABLE_ATTRS.select { |attr| attr.is_a?(Hash) }.map(&:keys).flatten

      # Build queries and ranks for each associated model
      associated_queries = associated_tables.map do |assoc_model|
        "#{assoc_model}.#{SEARCH_COLUMN} @@ to_tsquery('simple', '#{sanitized_term}')"
      end
      associated_ranks = associated_tables.map do |assoc_model|
        "COALESCE(ts_rank(#{assoc_model}.#{SEARCH_COLUMN}, to_tsquery('simple', '#{sanitized_term}')), 0)"
      end

      # Combine main model ans associated model for query
      search_conditions = ([base_query] + associated_queries).join(" OR ")
      search_ranks = ([base_rank] + associated_ranks).join(", ")

      join_tables = associated_tables.map do |associated_table|
        if associated_table.to_s.end_with?("_translations")
          if model.table_name.to_sym == associated_table.to_s.split("_").first.pluralize.to_sym
            :translations
          else
            [associated_table.to_s.split("_").first.pluralize.to_sym, associated_table.to_s.split("_").first.pluralize.to_sym => :translations]
          end
        else
          associated_table
        end
      end

      select(model.column_names, "GREATEST(#{search_ranks}) AS rank")
        .left_joins(join_tables.flatten)
        .where(search_conditions, term: "#{term}:*")
        .order("rank DESC")
        .distinct
    end
  end
end
