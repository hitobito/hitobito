#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
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

      scope = super.reorder(Arel.sql(sort_expression))
      scope = scope.joins(join_tables)
      return scope unless scope.distinct_value

      select_values = scope.select_values.presence || "#{model_class.table_name}.*"
      scope.select(select_values, sort_expression_attrs)
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
        subquery = entries.select(sort_expression_attrs).joins(join_tables).unscope(:order).distinct_on(:id)
        model_class.select("*").from(subquery, :subquery)
          .reorder(Arel.sql(sort_expression.gsub(TABLE_WITH_COLUMN, '\1')))
      end
    end

    def sorting?
      params[:sort].present? && sortable?(params[:sort])
    end

    # Return sort columns from defined mappings or as null_safe_sort from parameter.
    def sort_columns
      sort_mappings = sort_mappings_with_indifferent_access
      sort_columns_expression = sort_mappings[params[:sort]].is_a?(Hash) ? sort_mappings.dig(params[:sort], :order) : sort_mappings[params[:sort]]
      sort_columns_expression || "#{model_class.table_name}.#{params[:sort]}"
    end

    def join_tables
      sort_mappings_with_indifferent_access[params[:sort]].is_a?(Hash) ?
      sort_mappings_with_indifferent_access[params[:sort]][:joins] : nil
    end

    # Return the sort expression to be used in the list query.
    def sort_expression
      Array(sort_columns).collect { |c| "#{c} #{sort_dir}" }.join(", ") + " NULLS LAST"
    end

    # Return the sort expression attributes without sort directory, to add to query select list
    # Reject sort expression attributes from same table, to prevent ambiguous selection
    # of attributes
    def sort_expression_attrs
      Array(sort_columns).reject { |col| model_class.column_names.include?(col.split(".")[-1]) }
        .map(&:to_s)
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
  end
end
