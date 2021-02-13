# encoding: utf-8

#  Copyright (c) 2017, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class SqlConditionBuilder

    def initialize(search_string, search_tables_and_fields)
      @search_string = search_string
      @search_tables_and_fields = search_tables_and_fields
    end

    # Concat the word clauses with AND.
    def search_conditions
      search_word_conditions.reduce do |query, condition|
        query.and(condition)
      end
    end

    private

    # Split the search query in single words and create a list of word clauses.
    def search_word_conditions
      @search_string.split(/\s+/).map { |w| search_word_condition(w) }
    end

    # Create a list of Arel #matches queries for each column and the given
    # word.
    def search_word_condition(word)
      search_column_condition(word).reduce do |query, condition|
        query.or(condition)
      end
    end

    def search_column_condition(word)
      @search_tables_and_fields.map do |table_field|
        table_name, field = table_field.split(".", 2)
        table = Arel::Table.new(table_name)
        table[field].matches(Arel::Nodes::Quoted.new("%#{word}%"))
      end
    end

  end
end
