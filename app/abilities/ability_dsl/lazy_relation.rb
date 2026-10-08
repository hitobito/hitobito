# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl
  # A subquery condition value that is only built when the condition is evaluated.
  # Allows a constraint to depend on another ability of the same user without building
  # that ability while the current one is still being defined.
  class LazyRelation
    def initialize(&block)
      @block = block
    end

    def relation
      @relation ||= @block.call
    end

    def inspect
      "lazy_relation"
    end
  end
end
