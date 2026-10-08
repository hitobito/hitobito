# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl
  # Evaluates the constraints of ability configs for one user.
  class ConstraintEvaluator
    def initialize(user_context)
      @user_context = user_context
      @abilities = {}
      @results = {}
    end

    # The condition of the given config, restricted by its generals.
    def condition(config)
      rule = evaluate(config, config.permission)
      return if rule.nil?

      Condition.all_of(rule, *config.generals.map { |g| evaluate(g, config.permission) })
    end

    def class_side_allowed?(config)
      result = evaluate(config, :any)
      return false if result.nil?
      return true if result == {}

      raise ArgumentError, "Class side constraint #{name(config)} must return {} or nil, " \
        "but returned #{result.inspect}"
    end

    private

    def evaluate(config, permission)
      key = [config.ability_class, permission, config.constraint]
      return @results[key] if @results.key?(key)

      @results[key] =
        validate(config, ability(config.ability_class, permission).send(config.constraint))
    end

    def ability(ability_class, permission)
      @abilities[[ability_class, permission]] ||= ability_class.new(@user_context, permission)
    end

    def validate(config, result)
      return result if result.nil? || result.is_a?(Hash) || result.is_a?(Condition)

      raise ArgumentError, "Constraint #{name(config)} must return a Hash, " \
        "an AbilityDsl::Condition or nil, but returned #{result.inspect}"
    end

    def name(config)
      "#{config.ability_class.name}##{config.constraint}"
    end
  end
end
