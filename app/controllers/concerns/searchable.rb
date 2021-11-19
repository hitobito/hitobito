# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
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

    prepend Prepends
  end

  # Prepended methods for searching.
  module Prepends

    private

    # Enhance the list entries with an optional search criteria
    def list_entries
      super.where(search_conditions)
    end

    # Concat the word clauses with AND.
    def search_conditions
      if search_support? && params[:q].present?
        search_condition(*self.class.search_tables_and_fields)
      end
    end

    def search_condition(*fields)
      SearchStrategies::SqlConditionBuilder.new(params[:q], fields).search_conditions
    end


    # Returns true if this controller has searchable columns.
    def search_support?
      search_columns.present?
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
