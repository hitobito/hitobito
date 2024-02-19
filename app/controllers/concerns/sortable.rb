#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
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

    # Puts null and empty strings last
    def null_safe_sort(sort_expression)
      table_attr, direction = sort_expression.split

      model_name, attribute_name = table_attr.split('.')

      column_type = model_name.singularize.classify.constantize.attribute_types[attribute_name].type

      null_safe = 'CASE'
      null_safe << " WHEN #{table_attr} IS NULL THEN 1"
      null_safe << " WHEN #{table_attr} = '' THEN 1" if column_type == :string      
      null_safe << " ELSE 0 END"
      [null_safe, sort_expression]
    end
  end

  # Prepended methods for sorting.
  module Prepends

    private

    # Enhance the list entries with an optional sort order.
    def list_entries
      if sorting?
        super.select('*', Arel.sql(sort_expression)).reorder(Arel.sql(sort_expression_name))
      else
        super
      end
    end

    def sorting?
      params[:sort].present? && sortable?(params[:sort])
    end
    # Return sort columns from defined mappings or as null_safe_sort from parameter.
    def sort_columns
      sort_mappings_with_indifferent_access[params[:sort]] ||
        self.class.null_safe_sort("#{model_class.table_name}.#{params[:sort]}")
    end

    # Return the sort expression to be used in the list query.
    def sort_expression(alias: true, aggregate_function: false)
      (Array(sort_columns).map.with_index do |c, index|
        alias_name = "order_case_#{index}"
        if aggregate_function
          "MAX(#{c.split(/\sAS\s/i).first}) AS #{alias_name}"
        else
          # cut off current alias if sort_column already had an alias defined
          "#{c.split(/\sAS\s/i).first} AS #{alias_name}"
        end
      end).join(', ')
    end

    def sort_expression_name
      (Array(sort_columns).map.with_index do |c, index|
        "order_case_#{index} #{params[:sort_dir]}"
      end).join(', ')
    end

    # The sort direction, either 'asc' or 'desc'.
    def sort_dir
      params[:sort_dir] == 'desc' ? 'desc' : 'asc'
    end

    # Returns true if the passed attribute is sortable.
    def sortable?(attr)
      model_class.column_names.include?(attr.to_s) ||
        sort_mappings_with_indifferent_access.include?(attr)
    end
  end
end
