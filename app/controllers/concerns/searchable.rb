# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# The search functionality for the index table.
# Extracted into an own module for convenience.
module Searchable

  extend ActiveSupport::Concern

  included do
    class_attribute :search_columns
    self.search_columns = []

    helper_method :search_support?

    include Includes
    prepend Prepends
  end

  # Prepended methods for searching.
  module Prepends

    private

    def search_param
      return '' unless params.key?(search_key)

      params[search_key].to_s.strip
    end

    # Enhance the list entries with an optional search criteria
    def list_entries
      super.where(search_conditions)
    end

    # Concat the word clauses with AND.
    def search_conditions
      if search_support? && search_param.present?
        search_condition(*self.class.search_tables_and_fields)
      end
    end

    def search_condition(*fields)
      SearchStrategies::SqlConditionBuilder.new(search_param, fields).search_conditions
    end

    # Returns true if this controller has searchable columns.
    def search_support?
      search_columns.present?
    end

  end

  # Included methods for searching.
  module Includes
    def search_key
      :q
    end
  end

  # Class methods for Searchable.
  module ClassMethods

    # All search columns divided in table and field names.
    def search_tables_and_fields
      @search_tables_and_fields ||= search_columns.map do |f|
        if f.to_s.include?('.')
          f
        else
          "#{model_class.table_name}.#{f}"
        end
      end
    end

  end

end
