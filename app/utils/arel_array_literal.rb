# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Builder for postgres array literals
class ArelArrayLiteral
  attr_reader :items

  def initialize(items)
    @items = items
  end

  def to_sql
    # unfortunately arel does not support the postgres ARRAY-literal
    quoted_items = items.map { |item| Arel::Nodes.build_quoted(item).to_sql }
    Arel::Nodes::SqlLiteral.new("ARRAY[#{quoted_items.join(",")}]")
  end

  def eql?(other)
    self.class == other.class && self.items == other.items
  end
end
