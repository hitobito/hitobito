# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# The search functionality for the index table.
# Extracted into an own module for convenience.
module Searchable
  def self.included(controller)
    # Define an array of searchable columns in your subclassing controllers.
    controller.class_attribute :search_columns
    controller.search_columns = []

    controller.helper_method :search_support?

    controller.alias_method_chain :list_entries, :search
  end

  private

  # Enhance the list entries with an optional search criteria
  def list_entries_with_search
    list_entries_without_search.where(search_condition(*search_columns))
  end

  # Compose the search condition with a basic SQL OR query.
  def search_condition(*columns)
    if columns.present? && params[:q].present?
      terms = search_terms
      col_condition = search_column_conditions(columns)
      clause = terms.collect { |_| "(#{col_condition})" }.join(' AND ')

      ["(#{clause})"] + terms.collect { |t| [t] * columns.size }.flatten
    end
  end

  def search_terms
    params[:q].split(/\s+/).collect { |t| "%#{t}%" }
  end

  def search_column_conditions(columns)
    columns.collect do |f|
      col = f.to_s.include?('.') ? f : "#{model_class.table_name}.#{f}"
      "#{col} LIKE ?"
    end.join(' OR ')
  end

  # Returns true if this controller has searchable columns.
  def search_support?
    search_columns.present?
  end

end
