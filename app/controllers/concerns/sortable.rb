#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Sort functionality for the index table.
# Extracted into an own module for convenience.
module Sortable
  extend ActiveSupport::Concern

  SUBQUERY = /\bFROM\s+\(\s*SELECT\b/i
  GROUPED_QUERY = /\bGROUP\s+BY\b/i
  TABLE_WITH_COLUMN = /\b\w+\.(\w+)/
  SIMPLE_SORT_EXPRESSION = /^\s*[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*\s+(asc|desc)\s+(NULLS\s+(FIRST|LAST))?\s*$/

  # Adds a :sort_mappings class attribute.
  included do
    class_attribute :sort_mappings_with_indifferent_access
    self.sort_mappings = {}

    class_attribute :default_sort

    helper_method :sortable?

    prepend Prepends
  end

  module ClassMethods
    def sort_mappings=(hash)
      self.sort_mappings_with_indifferent_access = hash.with_indifferent_access
    end
  end

  # Prepended methods for sorting.
  module Prepends
    private

    # Enhance the list entries with an optional sort order.
    def list_entries
      return super unless sorting?

      if sort_expression.match?(SIMPLE_SORT_EXPRESSION) && table_exists?(sort_expression_attrs.split(".").first)
        sort_by_sort_expression(super)
      else
        scope = super.joins(join_tables).reorder(Arel.sql(sort_expression))
        return scope unless scope.distinct_value

        select_values = scope.select_values.presence || "#{model_class.table_name}.*"
        scope.select(select_values, sort_expression_attrs)
      end
    end

    def sort_by_sort_expression(entries)
      return entries unless sorting?

      if sort_expression_attrs.empty? # no join needed
        entries.reorder(sort_expression)
      elsif entries.to_sql.match?(SUBQUERY) # already selecting from a subquery (e.g. people_controller)
        entries.reorder(sort_expression.gsub(TABLE_WITH_COLUMN, '\1'))
      elsif entries.to_sql.match?(GROUPED_QUERY) # already selecting from a grouped query (e.g. sbv/song_counts_controller.rb)
        entries.select(model_class.column_names, "MAX(#{sort_expression_attrs}) AS #{sort_expression_attrs.gsub(TABLE_WITH_COLUMN, '\1')}")
          .joins(join_tables)
          .reorder(Arel.sql(sort_expression.gsub(TABLE_WITH_COLUMN, '\1')))
      else
        subquery = entries.unscope(:select, :order).select(sort_expression_attrs, model_class.column_names).joins(join_tables).distinct_on(:id)
        model_class.select("*").from(subquery, :subquery)
          .reorder(Arel.sql(sort_expression.gsub(TABLE_WITH_COLUMN, '\1')))
      end
    end

    def model_table_name
      model_class.table_name
    end

    def sorting?
      params[:sort].present? && sortable?(params[:sort])
    end

    def sort_columns
      sort_columns_expression = sort_mappings_with_indifferent_access[params[:sort]].is_a?(Hash) ?
                                sort_mappings_with_indifferent_access[params[:sort]][:order] :
                                sort_mappings_with_indifferent_access[params[:sort]]
      sort_columns_expression || params[:sort].to_s
    end

    def join_tables
      sort_mappings_with_indifferent_access[params[:sort]].is_a?(Hash) ?
      sort_mappings_with_indifferent_access[params[:sort]][:joins] : nil
    end

    # Return the sort expression to be used in the list query.
    def sort_expression
      if sort_expression_attrs.empty?
        Array(sort_columns).collect { |c|
          "#{model_table_name}.#{c} #{sort_dir} NULLS LAST"
        }.join(", ")
      else
        Array(sort_columns).collect { |c| "#{c} #{sort_dir} NULLS LAST" }.join(", ")
      end
    end

    # Return the sort expression attributes without sort directory, to add to query select list
    # Reject sort expression attributes from same table, to prevent ambiguous selection
    # of attributes
    def sort_expression_attrs
      Array(sort_columns).reject { |col| model_class.column_names.include?(col) }
        .collect { |c| c.to_s }
        .join(", ")
    end

    # The sort direction, either 'asc' or 'desc'.
    def sort_dir
      (params[:sort_dir] == "desc") ? "desc" : "asc"
    end

    # Returns true if the passed attribute is sortable.
    def sortable?(attr)
      model_class.column_names.include?(attr.to_s) ||
        sort_mappings_with_indifferent_access.include?(attr)
    end

    def table_exists?(table_name)
      ActiveRecord::Base.connection.table_exists?(table_name)
    end
  end
end
