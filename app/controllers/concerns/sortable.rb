#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Sort functionality for the index table.
# Extracted into an own module for convenience.
module Sortable
  extend ActiveSupport::Concern

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
      if sorting?
        # Get only the sort_expression attribute not included in
        # the attributes of current model_class, to select in query
        subquery = super.select("#{model_table_name}.*", sort_expression_attrs).joins(join_tables)

        model_class
          .select("#{model_table_name}.*")
          .from(subquery, model_table_name)
          .reorder(Arel.sql(sort_expression))
      else
        super
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
  end
end
