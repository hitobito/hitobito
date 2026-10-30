# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SearchStrategies::SqlConditionBuilder
  class Matcher
    def initialize(table_field, word)
      @table_name, @field = table_field.split(".", 2)
      @word = word
    end

    def match
      column.matches(quoted_word)
    end

    def applies?
      true
    end

    private

    def column
      table = Arel::Table.new(@table_name)
      arel_column = ActiveRecord::Base.with_connection do |c|
        c.schema_cache.columns_hash(@table_name).fetch(@field)
      end
      if arel_column.type == :integer
        Arel::Nodes::SqlLiteral.new("#{table.name}." + "#{table[@field].name}::text")
      else
        table[@field]
      end
    end

    def quoted_word
      Arel::Nodes::Quoted.new("%#{@word}%")
    end
  end
end
