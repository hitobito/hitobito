# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl
  # The ids of the records another ability of the same user may perform the given action on.
  # In memory, the associated record of a foreign key condition is checked with that ability,
  # which also works for new records.
  class AccessibleIds < LazyRelation
    attr_reader :model_class, :action

    def initialize(model_class, action, ability_class, user)
      @model_class = model_class
      @action = action
      @ability_class = ability_class
      @user = user
      super() do
        model_class.accessible_by(ability, action).unscope(:select).select(model_class.primary_key)
      end
    end

    def ability
      @ability ||= @ability_class.new(@user)
    end

    def allows?(record)
      record.is_a?(model_class) && ability.can?(action, record)
    end

    def inspect
      "accessible_ids(#{model_class.name}, #{action.inspect})"
    end
  end
end
