# frozen_string_literal: true

# CanCan is inefficient when using AR queries to filter the
module Hitobito
  module CanCan
    module ConditionsMatcher
      def condition_match?(attribute, value)
        case value
        when ActiveRecord::Relation
          ar_condition_match?(attribute, value)
        else
          super
        end
      end

      def ar_condition_match?(attribute, value)
        return false if attribute.nil?

        if attribute.is_a?(Array) || (defined?(ActiveRecord) && attribute.is_a?(ActiveRecord::Relation) && attribute.loaded?)
          value.where(id: attribute.pluck(:id)).exists?
        elsif (defined?(ActiveRecord) && attribute.is_a?(ActiveRecord::Relation))
          value.where(id: attribute.select(:id)).exists?
        else
          value.where(id: attribute.id).exists?
        end
      end
    end
  end
end

CanCan::ConditionsMatcher.prepend(Hitobito::CanCan::ConditionsMatcher)
