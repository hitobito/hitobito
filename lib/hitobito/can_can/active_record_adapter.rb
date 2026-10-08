# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require_relative "condition_matching"

module Hitobito
  module CanCan
    class ActiveRecordAdapter < ::CanCan::ModelAdapters::ActiveRecord5Adapter
      ::CanCan::ModelAdapters::AbstractAdapter.inherited(self)

      extend ConditionMatching

      def self.for_class?(model_class)
        model_class <= ActiveRecord::Base
      end

      def conditions
        resolve_values(super)
      end

      private

      def sanitize_sql(conditions)
        super(resolve_values(conditions))
      end

      def resolve_values(conditions)
        return conditions unless conditions.is_a?(Hash)

        conditions.each_with_object({}) do |(key, value), resolved|
          case value
          when AbilityDsl::Condition
            resolved[@model_class.primary_key] = value.to_relation(@model_class)
          when AbilityDsl::LazyRelation then resolved[key] = value.relation
          when Hash then resolved[key] = resolve_values(value)
          else resolved[key] = value
          end
        end
      end
    end
  end
end
