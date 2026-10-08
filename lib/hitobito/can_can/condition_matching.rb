# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Hitobito
  module CanCan
    # Matches condition values in memory which cancancan itself only supports in SQL:
    # subquery relations, arrays containing ranges and AbilityDsl::Condition trees.
    module ConditionMatching
      def override_condition_matching?(subject, name, value)
        special_value?(value) || super
      end

      def matches_condition?(subject, name, value)
        case value
        when AbilityDsl::Condition then value.matches?(subject)
        when AbilityDsl::LazyRelation then relation_includes?(value.relation, subject.send(name))
        when ActiveRecord::Relation then relation_includes?(value, subject.send(name))
        when Array then ranges_include?(value, subject.send(name))
        else super
        end
      end

      private

      def special_value?(value)
        case value
        when AbilityDsl::Condition, AbilityDsl::LazyRelation, ActiveRecord::Relation then true
        when Array then value.any?(Range)
        else false
        end
      end

      def ranges_include?(values, attribute)
        values.any? do |value|
          value.is_a?(Range) ? !attribute.nil? && value.cover?(attribute) : value == attribute
        end
      end

      def relation_includes?(relation, attribute)
        return false if attribute.nil?

        memo = (relation_memos[relation] ||= {})
        memo.fetch(attribute) { memo[attribute] = query_relation_includes?(relation, attribute) }
      end

      def query_relation_includes?(relation, attribute)
        column = relation.select_values.first || relation.klass.primary_key
        if column.is_a?(Symbol) || column.to_s.match?(/\A[\w.]+\z/)
          relation.unscope(:select).where(column => attribute).exists?
        else
          relation.connection.select_value(
            relation.klass.sanitize_sql_array(["SELECT ? IN (#{relation.to_sql})", attribute])
          )
        end
      end

      def relation_memos
        @relation_memos ||= ObjectSpace::WeakMap.new
      end
    end
  end
end
