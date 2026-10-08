# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl
  # Combines cancancan condition hashes with OR (any_of), AND (all_of) and NOT (none_of).
  # A condition is evaluated in memory by matching its hashes with cancancan, and in SQL by
  # compiling each hash to a subquery on the primary key.
  #
  # Operands are hashes, conditions or nil. nil means "not applicable" and is dropped,
  # {} means "unconditionally".
  class Condition
    NEVER = {id: [].freeze}.freeze

    class << self
      def any_of(*operands)
        operands = flatten(operands.compact, AnyOf)
        return nil if operands.empty?
        return {} if operands.any? { |o| unconditional?(o) }

        operands.one? ? operands.first : AnyOf.new(operands)
      end

      def all_of(*operands)
        operands = operands.compact
        return nil if operands.empty?

        operands = flatten(operands.reject { |o| unconditional?(o) }, AllOf)
        return {} if operands.empty?

        operands = merge_disjoint_hashes(operands)
        operands.one? ? operands.first : AllOf.new(operands)
      end

      def none_of(*operands)
        operand = any_of(*operands)
        case operand
        when nil then nil
        when NoneOf then operand.operand
        else unconditional?(operand) ? NEVER : NoneOf.new(operand)
        end
      end

      def matches?(condition, subject)
        if condition.is_a?(Condition)
          condition.matches?(subject)
        elsif unconditional?(condition)
          true
        else
          rule = CanCan::Rule.new(true, :match, subject.class, condition)
          rule.matches_conditions?(:match, subject)
        end
      end

      def to_relation(condition, model_class)
        relation =
          if condition.is_a?(Condition)
            condition.to_relation(model_class)
          else
            model_class.unscoped { hash_relation(condition, model_class) }
          end
        relation.select(model_class.primary_key)
      end

      private

      def unconditional?(operand)
        operand.is_a?(Hash) && operand.empty?
      end

      def flatten(operands, type)
        operands.flat_map { |o| o.is_a?(type) ? o.operands : [o] }
      end

      def merge_disjoint_hashes(operands)
        merged = {}
        others = operands.reject do |o|
          next false unless o.is_a?(Hash) && (merged.keys & o.keys).empty?

          merged.merge!(o)
        end
        merged.empty? ? others : [merged, *others]
      end

      def hash_relation(conditions, model_class)
        rule = CanCan::Rule.new(true, :match, model_class, conditions)
        Hitobito::CanCan::ActiveRecordAdapter.new(model_class, [rule]).database_records
      end
    end

    attr_reader :operands

    def initialize(operands)
      @operands = operands.freeze
      freeze
    end

    def inspect
      "#{self.class.name.demodulize.underscore}(#{operands.map(&:inspect).join(", ")})"
    end
    alias_method :to_s, :inspect

    private

    def matching(operand, model_class)
      {model_class.primary_key => Condition.to_relation(operand, model_class)}
    end

    class AnyOf < Condition
      def matches?(subject)
        operands.any? { |o| Condition.matches?(o, subject) }
      end

      def to_relation(model_class)
        operands.map { |o| model_class.unscoped.where(matching(o, model_class)) }.reduce(:or)
      end
    end

    class AllOf < Condition
      def matches?(subject)
        operands.all? { |o| Condition.matches?(o, subject) }
      end

      def to_relation(model_class)
        operands.reduce(model_class.unscoped) do |relation, o|
          relation.where(matching(o, model_class))
        end
      end
    end

    class NoneOf < Condition
      def initialize(operand)
        super([operand])
      end

      def operand
        operands.first
      end

      def matches?(subject)
        !Condition.matches?(operand, subject)
      end

      def to_relation(model_class)
        model_class.unscoped.where.not(matching(operand, model_class))
      end
    end
  end
end
