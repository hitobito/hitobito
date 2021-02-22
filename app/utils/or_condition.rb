# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Builder for SQL OR conditions
class OrCondition
  def initialize
    @conditions = []
  end

  def or(clause, *args)
    @conditions << {clause: clause, args: args}
    self
  end

  def delete(clause, *args)
    @conditions.delete_if do |condition|
      condition == {clause: clause, args: args}
    end
  end

  def to_a
    combined = @conditions.each_with_object({clauses: [], args: []}) { |condition, memo|
      memo[:clauses] << "(#{condition[:clause]})"
      memo[:args].push(*condition[:args])
    }

    [combined[:clauses].join(" OR "), *combined[:args]]
  end

  def blank?
    @conditions.empty?
  end
end
