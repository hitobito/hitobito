#  Copyright (c) 2017, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class SqlConditionBuilder
    class_attribute :matchers, default: {}

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
      conditions = search_column_condition(word)
      return nil if conditions.empty?

      conditions.reduce { |query, condition| query.or(condition) }
    end

    def search_column_condition(word)
      @search_tables_and_fields.flat_map do |table_field|
        case table_field
        when String
          klass = matchers.fetch(table_field) { self.class::Matcher }
          matcher = klass.new(table_field, word)
          matcher.match if matcher.applies?
        when Hash
          participant_field, mapping = table_field.first
          build_polymorphic_condition(participant_field, mapping, word)
        else
          []
        end
      end.compact
    end

    # Create an OR based condition to match polymorphic associations
    def build_polymorphic_condition(participant_field, mapping, word)
      conditions = mapping.flat_map do |participant_type, columns|
        columns.map do |column|
          matcher_class = matchers.fetch(column) { self.class::Matcher }
          matcher = matcher_class.new(column, word)

          Arel::Table.new(:event_participations)[participant_field.to_sym]
            .eq(participant_type)
            .and(matcher.match)
        end
      end

      conditions.reduce { |a, b| a.or(b) }
    end
  end
end
